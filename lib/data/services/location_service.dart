import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../models/navigation_model.dart';

class LocationService extends GetxService {
  final RxBool isLocationEnabled = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxList<Location> locations = RxList<Location>();
  final RxList<String> blocks = RxList<String>();
  final RxList<ClassNotification> upcomingClasses = RxList<ClassNotification>();
  
  final Rxn<NavigationRoute> activeRoute = Rxn<NavigationRoute>();
  final Rxn<NavigationProgress> navigationProgress = Rxn<NavigationProgress>();
  final RxBool isNavigating = false.obs;

  final LocationProvider _locationProvider = LocationProvider();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Parâmetros otimizados para bloco de ~2719m² (40x68m aprox.)
  static const double ACCURACY_THRESHOLD = 12.0; // metros - mais rigoroso para ambiente interno
  static const double MIN_DISTANCE_FILTER = 1.5; // metros - movimento mínimo (mais sensível)
  static const double STATIONARY_THRESHOLD = 1.0; // metros - muito sensível para detectar paradas
  static const int POSITION_BUFFER_SIZE = 7; // mais posições para suavização interna
  static const double MAX_SPEED_THRESHOLD = 8.0; // m/s - 28.8 km/h (mais realista para caminhada interna)
  
  // Parâmetros específicos para navegação interna
  static const double INDOOR_STEP_COMPLETION_DISTANCE = 3.0; // metros - quando considerar step completo
  static const double CORRIDOR_WIDTH_THRESHOLD = 2.5; // metros - largura típica de corredor
  static const int INDOOR_UPDATE_INTERVAL_STATIONARY = 15; // segundos entre updates quando parado
  
  // Buffer para suavização de posições
  final List<Position> _positionBuffer = [];
  Position? _lastValidPosition;
  DateTime? _lastUpdateTime;
  bool _isUserStationary = false;
  final RxDouble _currentAccuracy = 0.0.obs;

  Future<LocationService> init() async {
    final start = DateTime.now();
    print('[LocationService] Iniciando LocationService...');
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
      print('[LocationService] isLocationEnabled: \\${isLocationEnabled.value}');
      final blocksStart = DateTime.now();
      await getBlocks();
      print('[LocationService] getBlocks levou: \\${DateTime.now().difference(blocksStart).inMilliseconds}ms');
    } catch (e) {
      print('Erro ao inicializar serviço de localização: $e');
    }
    print('[LocationService] init levou: \\${DateTime.now().difference(start).inMilliseconds}ms');
    return this;
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied) {
        currentPosition.value = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _startLocationTracking(); 
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao solicitar permissão de localização: $e');
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Aplicar filtro de precisão mesmo para posição única
      if (position.accuracy <= ACCURACY_THRESHOLD) {
        currentPosition.value = position;
        return position;
      } else {
        print('Posição descartada por baixa precisão: ${position.accuracy}m');
        return currentPosition.value;
      }
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  // Filtrar posição baseado em critérios de precisão
  bool _isPositionValid(Position position) {
    // 1. Verificar precisão
    if (position.accuracy > ACCURACY_THRESHOLD) {
      print('Posição rejeitada: precisão muito baixa (${position.accuracy}m)');
      return false;
    }

    // 2. Verificar velocidade suspeita (possível erro de GPS)
    if (position.speed > MAX_SPEED_THRESHOLD) {
      print('Posição rejeitada: velocidade muito alta (${position.speed}m/s)');
      return false;
    }

    // 3. Se temos uma posição anterior, verificar se o movimento faz sentido
    if (_lastValidPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Se a distância é muito pequena, considerar como ruído
      if (distance < MIN_DISTANCE_FILTER && !isNavigating.value) {
        return false;
      }

      // Verificar se o movimento é fisicamente possível
      final timeElapsed = position.timestamp.difference(_lastValidPosition!.timestamp).inSeconds;
      if (timeElapsed > 0) {
        final calculatedSpeed = distance / timeElapsed;
        if (calculatedSpeed > MAX_SPEED_THRESHOLD) {
          print('Posição rejeitada: movimento impossível (${calculatedSpeed}m/s)');
          return false;
        }
      }
    }

    return true;
  }

  // Aplicar média móvel para suavizar as posições
  Position _smoothPosition(Position newPosition) {
    _positionBuffer.add(newPosition);
    
    // Manter apenas as últimas N posições
    if (_positionBuffer.length > POSITION_BUFFER_SIZE) {
      _positionBuffer.removeAt(0);
    }

    // Se temos poucas posições, retornar a atual
    if (_positionBuffer.length < 3) {
      return newPosition;
    }

    // Calcular média ponderada (posições mais recentes têm peso maior)
    double totalLat = 0;
    double totalLng = 0;
    double totalWeight = 0;

    for (int i = 0; i < _positionBuffer.length; i++) {
      final weight = i + 1; // peso crescente para posições mais recentes
      totalLat += _positionBuffer[i].latitude * weight;
      totalLng += _positionBuffer[i].longitude * weight;
      totalWeight += weight;
    }

    final smoothLat = totalLat / totalWeight;
    final smoothLng = totalLng / totalWeight;

    // Retornar nova posição suavizada mantendo outros dados da posição atual
    return Position(
      latitude: smoothLat,
      longitude: smoothLng,
      timestamp: newPosition.timestamp,
      accuracy: newPosition.accuracy,
      altitude: newPosition.altitude,
      altitudeAccuracy: newPosition.altitudeAccuracy,
      heading: newPosition.heading,
      headingAccuracy: newPosition.headingAccuracy,
      speed: newPosition.speed,
      speedAccuracy: newPosition.speedAccuracy,
    );
  }

  // Detectar se o usuário está parado
  void _updateStationaryStatus(Position position) {
    if (_lastValidPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      _isUserStationary = distance < STATIONARY_THRESHOLD;
    }
  }

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: isNavigating.value ? 1 : 2, // Mais sensível para ambiente interno
      ),
    ).listen((Position position) {
      _currentAccuracy.value = position.accuracy;
      
      // Aplicar filtros de validação
      if (!_isPositionValid(position)) {
        return; // Descartar posição inválida
      }

      // Detectar se está parado
      _updateStationaryStatus(position);
      
      // Se está parado e não navegando, não atualizar posição frequentemente
      if (_isUserStationary && !isNavigating.value) {
        final now = DateTime.now();
        if (_lastUpdateTime != null && 
            now.difference(_lastUpdateTime!).inSeconds < INDOOR_UPDATE_INTERVAL_STATIONARY) {
          return; // Não atualizar se atualizou recentemente e está parado
        }
      }

      // Aplicar suavização
      final smoothedPosition = _smoothPosition(position);
      
      // Atualizar posição atual
      currentPosition.value = smoothedPosition;
      _lastValidPosition = smoothedPosition;
      _lastUpdateTime = DateTime.now();

      // Atualizar navegação se ativa
      if (isNavigating.value && activeRoute.value != null && navigationProgress.value != null) {
        _updateNavigationProgress(smoothedPosition);
      }
    }, onError: (error) {
      print('Erro no stream de localização: $error');
      error.value = 'Erro ao rastrear localização: $error';
    });
  }

  Future<void> fetchLocations({String? type, String? block, int? floor, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getAllLocations(
        type: type,
        block: block,
        floor: floor,
        search: search
      );
      
      locations.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar localizações: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBlocks() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getBlocks();
      blocks.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar blocos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Location>> searchLocations(String query) async {
    try {
      if (query.isEmpty) return [];
      
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.searchLocations(query);
      return result;
    } catch (e) {
      error.value = 'Erro na busca de localizações: $e';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUpcomingClasses() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getUpcomingClasses();
      upcomingClasses.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar próximas aulas: $e';
    } finally {
      isLoading.value = false;
    }
  }

  double calculateDistance(double destLat, double destLng) {
    if (currentPosition.value == null) return 0;
    
    return Geolocator.distanceBetween(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
      destLat,
      destLng
    );
  }
  
  Future<bool> startNavigation(Location destination) async {
    try {
      if (currentPosition.value == null) {
        await requestLocationPermission();
      }
      
      if (currentPosition.value == null || 
          destination.latitude == null || 
          destination.longitude == null) {
        error.value = 'Não foi possível obter localização atual ou do destino';
        return false;
      }
      
      isLoading.value = true;
      
      final route = await _locationProvider.getNavigationRoute(
        LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        LatLng(destination.latitude!, destination.longitude!)
      );
      
      if (route == null) {
        error.value = 'Não foi possível calcular a rota para o destino';
        return false;
      }
      
      activeRoute.value = route;
      navigationProgress.value = NavigationProgress(
        currentStepIndex: 0,
        distanceToNextStep: route.steps[0].distance,
        distanceToDestination: route.totalDistance,
        estimatedTimeRemaining: route.estimatedDuration
      );
      
      // Limpar buffer e reiniciar rastreamento com configurações de navegação
      _positionBuffer.clear();
      _startLocationTracking();
      
      isNavigating.value = true;
      return true;
    } catch (e) {
      error.value = 'Erro ao iniciar navegação: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  void stopNavigation() {
    isNavigating.value = false;
    activeRoute.value = null;
    navigationProgress.value = null;
    _positionBuffer.clear();
    
    // Reiniciar rastreamento com configurações normais
    _startLocationTracking();
  }
  
  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  
  void _updateNavigationProgress(Position position) {
    if (activeRoute.value == null || navigationProgress.value == null) return;
    
    final route = activeRoute.value!;
    final currentStep = route.steps[navigationProgress.value!.currentStepIndex];
    
    final distanceToStepEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endPoint.latitude,
      currentStep.endPoint.longitude
    );
    
    final distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      route.steps.last.endPoint.latitude,
      route.steps.last.endPoint.longitude
    );
    
    navigationProgress.value = NavigationProgress(
      currentStepIndex: navigationProgress.value!.currentStepIndex,
      distanceToNextStep: distanceToStepEnd,
      distanceToDestination: distanceToDestination,
      estimatedTimeRemaining: (distanceToDestination / route.totalDistance * route.estimatedDuration).round()
    );
    
    if (distanceToStepEnd < INDOOR_STEP_COMPLETION_DISTANCE) { 
      _advanceToNextStep();
    }
  }
  
  void _advanceToNextStep() {
    if (activeRoute.value == null || navigationProgress.value == null) return;
    
    final nextStepIndex = navigationProgress.value!.currentStepIndex + 1;
    
    if (nextStepIndex >= activeRoute.value!.steps.length) {
      stopNavigation();
      return;
    }
    
    final nextStep = activeRoute.value!.steps[nextStepIndex];
    navigationProgress.value = NavigationProgress(
      currentStepIndex: nextStepIndex,
      distanceToNextStep: nextStep.distance,
      distanceToDestination: navigationProgress.value!.distanceToDestination,
      estimatedTimeRemaining: navigationProgress.value!.estimatedTimeRemaining
    );
  }

  double get currentAccuracy => _currentAccuracy.value;
  bool get isUserStationary => _isUserStationary;
  int get positionBufferSize => _positionBuffer.length;

  @override
  void onClose() {
    _stopLocationTracking();
    super.onClose();
  }
}