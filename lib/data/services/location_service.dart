import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../models/navigation_model.dart';
import 'websocket_service.dart';

enum MultiFloorNavigationStage { toStairs, stairs, fromStairs, none }

class LocationService extends GetxService {
  final _provider = LocationProvider();
  
  // Estado observável
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxBool isNavigating = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  // Dados de navegação
  final Rxn<NavigationRoute> activeRoute = Rxn<NavigationRoute>();
  final Rxn<NavigationRoute> _originalRoute = Rxn<NavigationRoute>(); // Rota completa original
  final Rxn<NavigationProgress> navigationProgress = Rxn<NavigationProgress>();
  final Rx<MultiFloorNavigationStage> multiFloorStage = MultiFloorNavigationStage.none.obs;
  
  // Dados de estruturas
  final Rxn<Map<String, dynamic>> nearestStructure = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> roomsOnFloor = <Map<String, dynamic>>[].obs;
  
  StreamSubscription<Position>? _positionStream;
  
  // Gerenciadores
  final List<Position> _positionBuffer = [];
  Position? _lastValidPosition;

  // ============ INICIALIZAÇÃO ============

  @override
  void onInit() {
    super.onInit();
    _setupReactiveListeners();
  }

  void _setupReactiveListeners() {
    ever(nearestStructure, (structure) {
      if (structure == null || isNavigating.value) return;
      _notifyStructureChange(structure);
    });
  }

  Future<void> _notifyStructureChange(Map<String, dynamic> structure) async {
    final pos = currentPosition.value;
    if (pos == null || structure['id'] == null) return;

    final ws = await _getWebSocket();
    ws?.sendPosition(
      position: [pos.longitude, pos.latitude],
      structureId: structure['id'],
      floor: (structure['floors'] as List?)?.first,
    );
  }

  Future<WebSocketService?> _getWebSocket() async {
    try {
      if (!Get.isRegistered<WebSocketService>()) {
        final ws = Get.put(WebSocketService());
        await ws.connect();
        return ws;
      }
      final ws = Get.find<WebSocketService>();
      if (!ws.isConnected.value) await ws.connect();
      return ws;
    } catch (e) {
      return null;
    }
  }

  // ============ PERMISSÕES E LOCALIZAÇÃO ============

  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          error.value = 'Permissão de localização negada.';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        error.value = 'Permissão negada permanentemente. Ative nas configurações.';
        return false;
      }

      await getCurrentLocation();
      _startLocationTracking();
      return true;
    } catch (e) {
      error.value = 'Erro ao solicitar permissão: $e';
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (position.accuracy <= 1000.0) {
        currentPosition.value = position;
        await _notifyPositionChange(position);
        return position;
      }
      
      error.value = 'Localização com baixa precisão (${position.accuracy}m)';
      return currentPosition.value;
    } on TimeoutException {
      error.value = 'Tempo esgotado ao obter localização';
      return null;
    } catch (e) {
      error.value = 'Erro ao obter localização: $e';
      return null;
    }
  }

  Future<void> _notifyPositionChange(Position position) async {
    final ws = await _getWebSocket();
    ws?.sendPosition(position: [position.longitude, position.latitude]);
  }

  void _startLocationTracking() {
    _positionStream?.cancel();
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: isNavigating.value ? 1 : 2,
      ),
    ).listen(
      _handlePositionUpdate,
      onError: (e) => error.value = 'Erro no rastreamento: $e',
    );
  }

  void _handlePositionUpdate(Position position) async {
    if (!_isValidPosition(position)) return;

    final smoothed = _smoothPosition(position);
    currentPosition.value = smoothed;
    
    await _notifyPositionChange(smoothed);

  }

  bool _isValidPosition(Position pos) {
    return pos.accuracy <= 1000.0 && pos.speed <= 8.0;
  }

  Position _smoothPosition(Position pos) {
    _positionBuffer.add(pos);
    if (_positionBuffer.length > 7) _positionBuffer.removeAt(0);
    if (_positionBuffer.length < 3) {
      _lastValidPosition = pos;
      return pos;
    }

    double totalLat = 0, totalLng = 0, totalWeight = 0;
    for (int i = 0; i < _positionBuffer.length; i++) {
      final weight = i + 1;
      totalLat += _positionBuffer[i].latitude * weight;
      totalLng += _positionBuffer[i].longitude * weight;
      totalWeight += weight;
    }

    final smoothed = Position(
      latitude: totalLat / totalWeight,
      longitude: totalLng / totalWeight,
      timestamp: pos.timestamp,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      altitudeAccuracy: pos.altitudeAccuracy,
      heading: pos.heading,
      headingAccuracy: pos.headingAccuracy,
      speed: pos.speed,
      speedAccuracy: pos.speedAccuracy,
    );

    _lastValidPosition = smoothed;
    return smoothed;
  }

  // ============ NAVEGAÇÃO (NOVO MÉTODO) ============

Future<void> fetchCompleteRoute({
  required int destinationRoomId,
  TransportMode mode = TransportMode.walking,
}) async {
  // ✅ Verifica se há localização disponível
  final hasLocation = currentPosition.value != null;
  
  isLoading.value = true;
  
  try {
    List<double>? startPosition;
    
    // Só envia 'start' se houver localização
    if (hasLocation) {
      final pos = currentPosition.value!;
      startPosition = [pos.longitude, pos.latitude];
      isNavigating.value = true; // Só marca como navegando se há localização
    }

    final routeResponse = await _provider.getCompleteRoute(
      start: startPosition, // Pode ser null
      destinationRoomId: destinationRoomId,
      mode: mode,
    );

    if (routeResponse == null) {
      error.value = 'Erro ao buscar dados';
      isNavigating.value = false;
      return;
    }

    // ✅ Verifica se é apenas estrutura (sem rota)
    if (routeResponse.isStructureOnly) {
      print('[LocationService] ✓ Modo: Apenas estrutura (sem navegação)');
      
      // Salva estrutura e rooms para visualização
      if (routeResponse.structure != null) {
        final structureData = Map<String, dynamic>.from(routeResponse.structure!);
        
        if (routeResponse.roomsByFloor != null) {
          structureData['roomsByFloor'] = routeResponse.roomsByFloor;
        }
        
        nearestStructure.value = structureData;
      }
      
      // Carrega rooms do primeiro andar
      if (routeResponse.roomsByFloor != null) {
        final floors = (routeResponse.structure?['floors'] as List?)
            ?.cast<int>()
            .toList() ?? [];
        
        if (floors.isNotEmpty) {
          final firstFloor = floors.first;
          final floorKey = firstFloor.toString();
          final rooms = routeResponse.roomsByFloor![floorKey];
          
          if (rooms != null) {
            roomsOnFloor.clear();
            roomsOnFloor.assignAll(rooms);
            print('[LocationService] ✓ Carregadas ${rooms.length} salas do andar $firstFloor');
          }
        }
      }
      
      isNavigating.value = false;
      return;
    }

    // ✅ Rota completa (com navegação)
    final route = routeResponse.route;
    if (route == null) {
      error.value = 'Rota não disponível';
      isNavigating.value = false;
      return;
    }


    activeRoute.value = route;
    _originalRoute.value = route;
    
    // Salva estrutura e roomsByFloor
    if (routeResponse.structure != null) {
      final structureData = Map<String, dynamic>.from(routeResponse.structure!);
      
      if (routeResponse.roomsByFloor != null) {
        structureData['roomsByFloor'] = routeResponse.roomsByFloor;
      }
      
      nearestStructure.value = structureData;
    }
    
    // Inicializa rooms do primeiro andar percorrido
    if (routeResponse.roomsByFloor != null) {
      final floorsTraversed = route.floorsTraversed;
      if (floorsTraversed.isNotEmpty) {
        final firstFloor = floorsTraversed.first;
        final floorKey = firstFloor.toString();
        final rooms = routeResponse.roomsByFloor![floorKey];
        
        if (rooms != null) {
          final filteredRooms = rooms
              .where((room) {
                final roomFloor = room['floor'];
                return roomFloor != null && roomFloor == firstFloor;
              })
              .toList();
          
          roomsOnFloor.clear();
          roomsOnFloor.assignAll(filteredRooms);
          
        }
      }
    }
    
    if (route.isMultiFloor) {
      multiFloorStage.value = MultiFloorNavigationStage.toStairs;
    } else {
      multiFloorStage.value = MultiFloorNavigationStage.none;
    }
    
    navigationProgress.value = NavigationProgress(
      currentSegmentIndex: 0,
      distanceToNextSegment: route.segments.first.distance,
      distanceToDestination: route.totalDistance,
      estimatedTimeRemaining: (route.estimatedTime * 60).toInt(),
    );
    
  } catch (e) {
    print('[LocationService] ❌ Erro: $e');
    error.value = 'Erro ao buscar rota: $e';
    isNavigating.value = false;
  } finally {
    isLoading.value = false;
  }
}
  // ============ NAVEGAÇÃO (MÉTODO LEGADO - COMPATIBILIDADE) ============

  Future<void> fetchAndSetInternalRoute({
    required int structureId,
    required int floor,
    required List<double> end,
    int? roomId,
  }) async {
    
    if (roomId != null) {
      await fetchCompleteRoute(
        destinationRoomId: roomId,
        mode: TransportMode.walking,
      );
    }
  }

  void stopNavigation() {
    isNavigating.value = false;
    activeRoute.value = null;
  _originalRoute.value = null;
    navigationProgress.value = null;
    multiFloorStage.value = MultiFloorNavigationStage.none;
    roomsOnFloor.clear();
    
    if (nearestStructure.value != null) {
      final updated = Map<String, dynamic>.from(nearestStructure.value!);
      updated.remove('isNavigating');
      nearestStructure.value = updated;
    }
  }

  
  void restoreFullRoute() {
    if (_originalRoute.value != null) {
      final originalRoute = _originalRoute.value!;
      final floorsTraversed = originalRoute.floorsTraversed;
      
      if (floorsTraversed.isEmpty) {
        activeRoute.value = originalRoute;
        return;
      }

      
      final completeSegments = <RouteSegment>[];
      
      
      final externalSegments = originalRoute.segments
          .where((seg) => seg.type == RouteSegmentType.external)
          .toList();
      completeSegments.addAll(externalSegments);
      
      
      final groundFloorSegments = originalRoute.segments
          .where((seg) => seg.floor == 0)
          .toList();
      completeSegments.addAll(groundFloorSegments);
      
      
      final destinationFloor = _getDestinationFloor(originalRoute);
      if (destinationFloor != null && destinationFloor == 1) {
        
        final transitionToFirst = originalRoute.segments
            .where((seg) => 
              seg.type == RouteSegmentType.transition &&
              (seg.fromFloor == 0 && seg.toFloor == 1 || seg.floor == 1 && seg.fromFloor == 0)
            )
            .toList();
        completeSegments.addAll(transitionToFirst);
        
        
        final firstFloorSegments = originalRoute.segments
            .where((seg) => seg.floor == 1)
            .toList();
        completeSegments.addAll(firstFloorSegments);
      }
      
      
      
      
      final totalDistance = completeSegments.fold<double>(
        0.0,
        (sum, seg) => sum + seg.distance,
      );
      
      
      activeRoute.value = NavigationRoute(
        segments: completeSegments,
        totalDistance: totalDistance,
        estimatedTime: totalDistance / 1.4 / 60,
        destination: originalRoute.destination,
        mode: originalRoute.mode,
        summary: originalRoute.summary,
      );
      
      
      final nearest = nearestStructure.value;
      final roomsByFloor = nearest?['roomsByFloor'] as Map<String, dynamic>?;
      if (roomsByFloor != null) {
        final floorKey = '0';
        final rooms = roomsByFloor[floorKey];
        if (rooms is List) {
          
          final filteredRooms = rooms
              .where((room) {
                final roomFloor = room['floor'];
                return roomFloor != null && roomFloor == 0;
              })
              .toList();
          
          roomsOnFloor.clear();
          roomsOnFloor.assignAll(filteredRooms.cast<Map<String, dynamic>>());
        }
      }
    }
  }

  /// Obtém a rota original completa (para uso interno)
  NavigationRoute? get originalRoute => _originalRoute.value;

  
  int? _getDestinationFloor(NavigationRoute route) {
    
    final internalSegments = route.segments
        .where((seg) => seg.floor != null)
        .toList();
    
    if (internalSegments.isNotEmpty) {
      // Retorna o andar do último segmento interno (onde está o destino)
      return internalSegments.last.floor;
    }
    
    
    final floorsTraversed = route.floorsTraversed;
    if (floorsTraversed.isNotEmpty) {
      return floorsTraversed.last;
    }
    
  return null;
  }

  void clearAllData() {
    _positionStream?.cancel();
    stopNavigation();
    currentPosition.value = null;
    nearestStructure.value = null;
    _positionBuffer.clear();
  }

  

  List<LatLng>? getPathForFloor(int floor) {
  final route = activeRoute.value;
  if (route == null) return null;
  final segments = route.segmentsForFloor(floor);
  if (segments.isEmpty) return null;
  return segments.expand((seg) => seg.path).toList();
  }

  List<int> getRouteFloors() {
  return activeRoute.value?.floorsTraversed ?? [];
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    super.onClose();
  }
}