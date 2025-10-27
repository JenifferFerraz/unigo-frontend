
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../models/navigation_model.dart';
import 'package:unigo_mobile/core/config/env_service.dart';
import 'websocket_service.dart';

enum MultiFloorNavigationStage { toStairs, stairs, fromStairs, none }

class LocationService extends GetxService {
  final Rx<MultiFloorNavigationStage> multiFloorStage = MultiFloorNavigationStage.none.obs;
  List<LatLng> _pathToStairs = [];
  List<LatLng> _pathFromStairs = [];
  List<LatLng> _stairsTransition = [];
  int? _destinationFloor;
  int? _navigationStructureId;
  final Rxn<Map<String, dynamic>> nearestStructure = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    ever(nearestStructure, (nearest) async {
      if (nearest != null && nearest['id'] != null && nearest['floors'] != null && nearest['floors'] is List && nearest['floors'].isNotEmpty) {
        final structureId = nearest['id'];
        final floor = nearest['floors'][0];
        final pos = currentPosition.value;
        if (pos != null) {
          try {
            WebSocketService ws;
            if (!Get.isRegistered<WebSocketService>()) {
              ws = Get.put(WebSocketService());
              await ws.connect();
            } else {
              ws = Get.find<WebSocketService>();
              if (!ws.isConnected.value) {
                await ws.connect();
              }
            }
            if (ws.isConnected.value) {
              ws.sendPosition(
                position: [pos.longitude, pos.latitude],
                structureId: structureId,
                floor: floor,
              );
            }
          } catch (e) {
            print('[LocationService] Erro ao reenviar posição para WebSocket após nearestStructure: $e');
          }
        }
      }
    });
  }
  final RxList<Map<String, dynamic>> roomsOnFloor = <Map<String, dynamic>>[].obs;
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
  static const double ACCURACY_THRESHOLD = 1000.0; // em metros
  static const double MIN_DISTANCE_FILTER = 1.5;
  static const double STATIONARY_THRESHOLD = 1.0;
  static const int POSITION_BUFFER_SIZE = 7;
  static const double MAX_SPEED_THRESHOLD = 8.0;
  
  // Parâmetros específicos para navegação interna
  static const double INDOOR_STEP_COMPLETION_DISTANCE = 3.0;
  static const double CORRIDOR_WIDTH_THRESHOLD = 2.5;
  static const int INDOOR_UPDATE_INTERVAL_STATIONARY = 15;
  
  // Buffer para suavização de posições
  final List<Position> _positionBuffer = [];
  Position? _lastValidPosition;
  DateTime? _lastUpdateTime;
  bool _isUserStationary = false;
  final RxDouble _currentAccuracy = 0.0.obs;

  Future<LocationService> init() async {
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
      await getBlocks();
    } catch (e) {
      print('Erro ao inicializar serviço de localização: $e');
    }
    return this;
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        error.value = 'Permissão de localização negada permanentemente. Ative nas configurações.';
        return false;
      }

      if (permission == LocationPermission.denied) {
        error.value = 'Permissão de localização negada.';
        return false;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        try {
          currentPosition.value = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          _startLocationTracking();
          return true;
        } catch (e) {
          if (e is TimeoutException) {
            error.value = 'Tempo esgotado ao tentar obter localização. Tente novamente.';
          } else {
            print('[LocationService] Erro ao obter localização: $e');
            error.value = 'Erro ao obter localização: $e';
          }
          return false;
        }
      }
      error.value = 'Estado de permissão inesperado: $permission';
      return false;
    } catch (e) {
      print('[LocationService] Erro ao solicitar permissão de localização: $e');
      error.value = 'Erro ao solicitar permissão de localização: $e';
      return false;
    }
  }

  Future<void> fetchAndSetInternalRoute({
    required int structureId,
    required int floor,
    required List<double> end,
    int? roomId,
  }) async {
    isLoading.value = true;
    error.value = '';
    _navigationStructureId = structureId; // Armazenar para uso posterior
    try {
      final pos = currentPosition.value;
      if (pos == null) {
        error.value = 'Posição atual não disponível';
        return;
      }
      final start = [pos.latitude, pos.longitude];
      final url = '${EnvService.apiBaseUrl}/internal-route/shortest-to-room';
      final body = {
        'structureId': structureId,
        'floor': floor,
        'start': [pos.longitude, pos.latitude],
      };
      if (roomId != null) body['roomId'] = roomId;

      final response = await GetConnect().post(url, body);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;
        
        // Detecta navegação multi-andar
        if (data is Map<String, dynamic> &&
            data.containsKey('pathToStairs') &&
            data.containsKey('stairsTransition') &&
            data.containsKey('pathFromStairs')) {
          
          // Armazenar andar de destino se disponível
          if (data.containsKey('destinationFloor')) {
            _destinationFloor = data['destinationFloor'] as int;
          }
          
          // Armazenar os 3 caminhos separadamente
          _pathToStairs = (data['pathToStairs'] as List)
              .map((p) => LatLng((p as List)[1], p[0]))
              .toList();
          
          final stairsFrom = data['stairsTransition']['from'] as List;
          final stairsTo = data['stairsTransition']['to'] as List;
          _stairsTransition = [
            LatLng(stairsFrom[1], stairsFrom[0]),
            LatLng(stairsTo[1], stairsTo[0]),
          ];
          
          _pathFromStairs = (data['pathFromStairs'] as List)
              .map((p) => LatLng((p as List)[1], p[0]))
              .toList();
          
          // Iniciar no estágio 1: indo para as escadas
          multiFloorStage.value = MultiFloorNavigationStage.toStairs;
          
          // Calcular distância total do primeiro trecho
          double totalDist = 0;
          for (int i = 1; i < _pathToStairs.length; i++) {
            totalDist += Distance().as(LengthUnit.Meter, _pathToStairs[i - 1], _pathToStairs[i]);
          }
          
          // Definir rota inicial (até as escadas)
          activeRoute.value = NavigationRoute(
            steps: [],
            totalDistance: totalDist,
            estimatedDuration: (totalDist / 1.4).toInt(), // ~1.4 m/s velocidade caminhada
            path: _pathToStairs,
          );
          
          isNavigating.value = true;
          
        } else {
          // Navegação no mesmo andar
          multiFloorStage.value = MultiFloorNavigationStage.none;
          
          List<List<double>> routePoints = [];
          if (data is Map<String, dynamic> && data.containsKey('path')) {
            routePoints = List<List<dynamic>>.from(data['path'])
                .map((p) => List<double>.from(p)).toList();
          } else if (data is List) {
            routePoints = data.map<List<double>>((p) => List<double>.from(p)).toList();
          }
          
          if (routePoints.isNotEmpty) {
            final List<LatLng> latlngs = routePoints.map((p) => LatLng(p[1], p[0])).toList();
            
            double totalDist = 0;
            for (int i = 1; i < latlngs.length; i++) {
              totalDist += Distance().as(LengthUnit.Meter, latlngs[i - 1], latlngs[i]);
            }
            
            activeRoute.value = NavigationRoute(
              steps: [],
              totalDistance: totalDist,
              estimatedDuration: (totalDist / 1.4).toInt(),
              path: latlngs,
            );
            
            isNavigating.value = true;
          }
        }
      } else {
        error.value = 'Erro ao buscar rota: ${response.statusText}';
      }
    } catch (e) {
      error.value = 'Erro ao buscar rota: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> checkMultiFloorTransition(LatLng userPosition, {double threshold = 3.0}) async {
    // Estágio 1: Indo para as escadas
    if (multiFloorStage.value == MultiFloorNavigationStage.toStairs && _pathToStairs.isNotEmpty) {
      final lastStairsPoint = _pathToStairs.last;
      final distance = Distance().as(LengthUnit.Meter, userPosition, lastStairsPoint);
      if (distance < threshold) {
        multiFloorStage.value = MultiFloorNavigationStage.stairs;
        // Mostrar a transição das escadas
        if (_stairsTransition.isNotEmpty) {
          activeRoute.value = NavigationRoute(
            steps: [],
            totalDistance: Distance().as(LengthUnit.Meter, _stairsTransition.first, _stairsTransition.last),
            estimatedDuration: 30, // estimativa de 30 segundos para subir/descer escadas
            path: _stairsTransition,
          );
        }
      }
    } 
    // Estágio 2: Nas escadas, aguardando chegar no outro andar
    else if (multiFloorStage.value == MultiFloorNavigationStage.stairs && _stairsTransition.isNotEmpty) {
      final stairsEnd = _stairsTransition.last;
      final distance = Distance().as(LengthUnit.Meter, userPosition, stairsEnd);
      if (distance < threshold) {
        multiFloorStage.value = MultiFloorNavigationStage.fromStairs;
        
        // Notificar backend sobre mudança de andar via WebSocket
        if (_destinationFloor != null && _navigationStructureId != null) {
          try {
            WebSocketService ws;
            if (!Get.isRegistered<WebSocketService>()) {
              ws = Get.put(WebSocketService());
              await ws.connect();
            } else {
              ws = Get.find<WebSocketService>();
              if (!ws.isConnected.value) {
                await ws.connect();
              }
            }
            if (ws.isConnected.value) {
              ws.sendPosition(
                position: [userPosition.longitude, userPosition.latitude],
                structureId: _navigationStructureId!,
                floor: _destinationFloor!,
              );
            }
          } catch (e) {
            print('[LocationService] Erro ao atualizar WebSocket: $e');
          }
        }
        
        // Mostrar o caminho do andar de destino
        activeRoute.value = NavigationRoute(
          steps: [],
          totalDistance: _pathFromStairs.fold<double>(0.0, (sum, point) {
            if (_pathFromStairs.indexOf(point) == 0) return 0;
            final prev = _pathFromStairs[_pathFromStairs.indexOf(point) - 1];
            return sum + Distance().as(LengthUnit.Meter, prev, point);
          }),
          estimatedDuration: 0,
          path: _pathFromStairs,
        );
      }
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (position.accuracy <= ACCURACY_THRESHOLD) {
        currentPosition.value = position;
        try {
          WebSocketService ws;
          if (!Get.isRegistered<WebSocketService>()) {
            ws = Get.put(WebSocketService());
            await ws.connect();
          } else {
            ws = Get.find<WebSocketService>();
            if (!ws.isConnected.value) {
              await ws.connect();
            }
          }
          if (ws.isConnected.value) {
            ws.sendPosition(
              position: [position.longitude, position.latitude],
              structureId: null,
              floor: null,
            );
          }
        } catch (e) {
          print('[LocationService] Erro ao garantir conexão/enviar posição para WebSocket: $e');
        }
        return position;
      } else {
        error.value = 'Localização obtida com baixa precisão (${position.accuracy}m). Aguarde ou tente novamente.';
        return currentPosition.value;
      }
    } catch (e) {
      if (e is TimeoutException) {
        error.value = 'Tempo esgotado ao tentar obter localização. Tente novamente.';
      } else {
        print('[LocationService] Erro ao obter localização: $e');
        error.value = 'Erro ao obter localização: $e';
      }
      return null;
    }
  }

  bool _isValidPosition(Position position) {
    // 1. Verificar precisão
    if (position.accuracy > ACCURACY_THRESHOLD) {
      return false;
    }

    // 2. Verificar velocidade reportada
    if (position.speed > MAX_SPEED_THRESHOLD) {
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
      final weight = i + 1;
      totalLat += _positionBuffer[i].latitude * weight;
      totalLng += _positionBuffer[i].longitude * weight;
      totalWeight += weight;
    }

    final smoothLat = totalLat / totalWeight;
    final smoothLng = totalLng / totalWeight;

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
        distanceFilter: isNavigating.value ? 1 : 2,
      ),
    ).listen((Position position) {
      _currentAccuracy.value = position.accuracy;

      if (!_isValidPosition(position)) {
        return;
      }

      _updateStationaryStatus(position);
      final now = DateTime.now();

      // Se usuário está parado e não navegando, reduzir atualizações
      if (_isUserStationary && !isNavigating.value) {
        if (_lastUpdateTime != null &&
            now.difference(_lastUpdateTime!).inSeconds < INDOOR_UPDATE_INTERVAL_STATIONARY) {
          return;
        }
      }

      final smoothedPosition = _smoothPosition(position);
      
      currentPosition.value = smoothedPosition;
      _lastValidPosition = smoothedPosition;
      _lastUpdateTime = DateTime.now();

      try {
        final ws = Get.isRegistered<WebSocketService>() ? Get.find<WebSocketService>() : null;
        if (ws != null && ws.isConnected.value) {
          ws.sendPosition(
            position: [smoothedPosition.latitude, smoothedPosition.longitude],
            structureId: null,
            floor: null,
          );
        }
      } catch (e) {
        print('[LocationService] Erro ao enviar posição para WebSocket: $e');
      }

      if (isNavigating.value && activeRoute.value != null && navigationProgress.value != null) {
        _updateNavigationProgress(smoothedPosition);
        
        // Verificar transição multi-andar (fire and forget)
        final userLatLng = LatLng(smoothedPosition.latitude, smoothedPosition.longitude);
        checkMultiFloorTransition(userLatLng).catchError((e) {
          print('[LocationService] Erro ao verificar transição multi-andar: $e');
        });
      }
    }, onError: (error) {
      print('Erro no stream de localização: $error');
      this.error.value = 'Erro ao rastrear localização: $error';
    });
  }

  Future<void> fetchLocations({String? type, String? block, int? floor, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getAllStructures();
      locations.clear();
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
      
      blocks.value = [];
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
    
    _startLocationTracking();
  }
  
  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  
  /// Limpa todos os dados de navegação e localização (usado no logout)
  void clearAllData() {
    // Para rastreamento
    _stopLocationTracking();
    
    // Limpa navegação ativa
    isNavigating.value = false;
    activeRoute.value = null;
    navigationProgress.value = null;
    
    // Limpa dados multi-andar
    multiFloorStage.value = MultiFloorNavigationStage.none;
    _pathToStairs.clear();
    _pathFromStairs.clear();
    _stairsTransition.clear();
    _destinationFloor = null;
    _navigationStructureId = null;
    
    // Limpa posição e buffers
    currentPosition.value = null;
    _positionBuffer.clear();
    _lastValidPosition = null;
    _lastUpdateTime = null;
    
    // Limpa listas de dados
    locations.clear();
    blocks.clear();
    upcomingClasses.clear();
    roomsOnFloor.clear();
    nearestStructure.value = null;
    
    // Reseta estados
    isLoading.value = false;
    error.value = '';
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