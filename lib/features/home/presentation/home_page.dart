import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../core/atoms/loading_screen.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';
import './components/feedback_tab.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/models/navigation_model.dart';
import '../../../data/providers/location_provider.dart' as provider;

class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showLocationSearch = false;
  bool _isInitialized = false;
  LocationService? _locationService;

  @override
  void initState() {
    super.initState();
    _initializeServices().then((_) {
      // Após inicializar, processa navegação se houver
      _processNavigationArguments();
    });
  }

  Future<void> _initializeServices() async {
    try {
      
      await _ensureWebSocketConnected();
      
      await _initializeLocationService();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// Garante conexão WebSocket
  Future<void> _ensureWebSocketConnected() async {
    try {
      if (!Get.isRegistered<WebSocketService>()) {
        final ws = Get.put(WebSocketService());
        await ws.connect();
      } else {
        final ws = Get.find<WebSocketService>();
        if (!ws.isConnected.value) {
          await ws.connect();
        }
      }
    } catch (e) {}
  }

  /// Inicializa LocationService
  Future<void> _initializeLocationService() async {
    try {
      if (Get.isRegistered<LocationService>()) {
        _locationService = Get.find<LocationService>();
      } else {
        _locationService = Get.put(LocationService());
        // Só tenta obter localização se não for visitante
        if (!_isVisitor) {
          await _locationService?.requestLocationPermission();
        }
      }
    } catch (e) {
      // Tenta criar um novo mesmo com erro
      try {
        _locationService = Get.put(LocationService(), permanent: false);
      } catch (e2) {}
    }
  }

  Future<void> _processNavigationArguments() async {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final roomId = args['roomId'] as int?;
    final structureId = args['structureId'] as int?;
    
    print('[HomePage] Argumentos recebidos: roomId=$roomId, structureId=$structureId');
    
    if (roomId != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || _locationService == null) return;
      
      try {
        final hasLocation = _locationService?.currentPosition.value != null;
        
        if (hasLocation) {
          print('[HomePage] Com localização, calculando rota para roomId=$roomId');
          await _fetchAndNavigateToRoom(roomId);
        } else {
          print('[HomePage] Sem localização, visualizando estrutura structureId=$structureId');
          if (structureId != null) {
            await _fetchAndVisualizeStructure(structureId);
          } else {
            _showError('Estrutura não especificada');
          }
        }
      } catch (e) {
        print('[HomePage] Erro ao processar navegação: $e');
        _showError('Erro ao iniciar navegação: $e');
      }
      return;
    }
  }

  /// Busca e navega para uma sala específica
  Future<void> _fetchAndNavigateToRoom(int roomId) async {
    try {
      // Verifica localização
      if (_locationService?.currentPosition.value == null) {
        _showError('Localização não disponível');
        return;
      }

      // Mostra loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculando rota...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Calcula rota usando roomId
      await _locationService?.fetchCompleteRoute(
        destinationRoomId: roomId,
        mode: TransportMode.walking,
      );

      Get.back(); // Fecha loading

      if (_locationService?.activeRoute.value == null) {
        _showError('Não foi possível calcular a rota');
        return;
      }

      // Confirma navegação
      final shouldNavigate = await _showAutoNavigationDialog();
      
      if (shouldNavigate == true) {
        _locationService?.isNavigating.value = true;
        _showSuccess('Navegação iniciada!');
      }
      
    } catch (e) {
      Get.back(); // Fecha loading em caso de erro
      print('[HomePage] Erro ao calcular rota para sala: $e');
      _showError('Erro ao calcular rota: $e');
    }
  }

  Future<void> _fetchAndVisualizeStructure(int structureId) async {
    try {
      final locationProvider = provider.LocationProvider();
      
      final routeResponse = await locationProvider.getCompleteRoute(
        start: null,
        destinationRoomId: structureId,
        mode: TransportMode.walking,
      );

      if (routeResponse?.structure != null) {
        final structureData = Map<String, dynamic>.from(routeResponse!.structure!);
        
        if (routeResponse.roomsByFloor != null) {
          structureData['roomsByFloor'] = routeResponse.roomsByFloor;
        }
        
        _locationService?.nearestStructure.value = structureData;

        if (routeResponse.roomsByFloor != null) {
          final floors = (routeResponse.structure!['floors'] as List?)
              ?.cast<int>()
              .toList() ?? [];
          
          if (floors.isNotEmpty) {
            final firstFloor = floors.first;
            final floorKey = firstFloor.toString();
            final rooms = routeResponse.roomsByFloor![floorKey];
            
            if (rooms is List) {
              final roomsList = rooms as List;
              if (roomsList.isNotEmpty) {
                _locationService?.roomsOnFloor.clear();
                _locationService?.roomsOnFloor.assignAll(
                  roomsList.cast<Map<String, dynamic>>()
                );
              }
            }
          }
        }

        _showSuccess('Estrutura carregada no mapa');
      }
    } catch (e) {
      _showError('Erro ao carregar estrutura: $e');
    }
  }

  /// Busca e inicia navegação para estrutura
  Future<void> _fetchAndNavigateToStructure(int structureId) async {
    try {
      // Verifica localização
      if (_locationService?.currentPosition.value == null) {
        _showError('Localização não disponível');
        return;
      }

      // Mostra loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculando rota...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Calcula rota
      await _locationService?.fetchCompleteRoute(
        destinationRoomId: structureId,
        mode: TransportMode.walking,
      );

      Get.back(); // Fecha loading

      if (_locationService?.activeRoute.value == null) {
        _showError('Não foi possível calcular a rota');
        return;
      }

      // Confirma navegação
      final shouldNavigate = await _showAutoNavigationDialog();
      
      if (shouldNavigate == true) {
        _locationService?.isNavigating.value = true;
        _showSuccess('Navegação iniciada! Siga a rota azul no mapa');
      }
      
    } catch (e) {
      Get.back(); // Fecha loading em caso de erro
      _showError('Erro ao calcular rota: $e');
    }
  }

  /// Dialog de confirmação de navegação automática
  Future<bool?> _showAutoNavigationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3C3CC0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.navigation, color: Color(0xFF3C3CC0)),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Rota Calculada', style: TextStyle(color: Colors.black87))),
          ],
        ),
        content: const Text(
          'A rota até a sala foi calculada. Deseja iniciar a navegação?',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3CC0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sim, navegar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Verifica se é visitante
  bool get _isVisitor {
    try {
      final authService = Get.find<AuthService>();
      return authService.currentUser.value == null ||
             (Get.arguments?['visitor'] == true);
    } catch (e) {
      return true; // Assume visitante em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aguarda inicialização
    if (!_isInitialized) {
      return const LoadingScreen(message: 'Inicializando serviços...');
    }

    // Se LocationService não foi criado, mostra erro
    if (_locationService == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF3C3CC0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Erro ao inicializar serviços',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                  });
                  _initializeServices();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: _buildAppBar(),
      drawer: _isVisitor ? null : Sidebar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  // ============ APP BAR ============

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3C3CC0),
      elevation: 0,
      leading: _buildLeading(),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset(
            'assets/images/Logo.png',
            height: 32,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLeading() {
    if (_isVisitor) {
      return IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _handleVisitorExit,
      );
    }

    return Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  /// Lida com saída do visitante
  Future<void> _handleVisitorExit() async {
    // Limpar dados
    if (Get.isRegistered<LocationService>()) {
      Get.find<LocationService>().clearAllData();
    }

    if (Get.isRegistered<WebSocketService>()) {
      final ws = Get.find<WebSocketService>();
      await ws.disconnect();
      await ws.clearSessionId();
    }

    Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
  }

  // ============ BODY ============

  Widget _buildBody() {
    return Stack(
      children: [
        const SizedBox.expand(
          child: MapWidget(zoom: 15.0, showUserLocation: true),
        ),

        if (_showLocationSearch)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationSearch(),
                _buildLocationBannerCompact(),
              ],
            ),
          ),

        if (!_showLocationSearch)
          _buildLocationBanner(),

        // 📊 Card de informações da rota (distância e tempo)
        _buildRouteInfoCard(),

        if (_isVisitor) const FeedbackTab(),
      ],
    );
  }

  Widget _buildLocationBanner() {
    return Obx(() {
      final position = _locationService?.currentPosition.value;
      if (position != null) return const SizedBox.shrink();

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.orange[100],
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Localização não ativada. Para uma experiência completa, '
                  'permita o acesso à localização.',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _requestLocationPermission,
                child: const Text(
                  'Ativar',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Banner de localização compacto (abaixo da busca)
  Widget _buildLocationBannerCompact() {
    return Obx(() {
      final position = _locationService?.currentPosition.value;
      if (position != null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange[800], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Localização desativada',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _requestLocationPermission,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ativar Agora',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Solicita permissão de localização
  Future<void> _requestLocationPermission() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingScreen(
        message: 'Obtendo sua localização...',
      ),
    );

    try {
      final permission = await _locationService?.requestLocationPermission();

      if (permission == true) {
        await _locationService?.getCurrentLocation();

        await _waitForAccurateLocation();

        _showSuccess('✓ Localização ativada com sucesso!');
      } else {
        _showError(
          _locationService?.error.value ??
              'Permissão de localização negada. '
              'Ative nas configurações do dispositivo.',
        );
      }
    } catch (e) {
      _showError('Erro ao obter localização: $e');
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Aguarda localização com boa precisão
  Future<void> _waitForAccurateLocation() async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final position = _locationService?.currentPosition.value;
      if (position != null && position.accuracy <= 20) {
        break;
      }
    }
  }

  // ============ FLOATING BUTTONS ============

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildNavigationButtons(),

        _buildFloorSelectionButton(),

        _buildSearchButton(),
      ],
    );
  }

  /// Botões durante navegação
  Widget _buildNavigationButtons() {
    return Obx(() {
      final isNavigating = _locationService?.isNavigating.value ?? false;
      if (!isNavigating) return const SizedBox.shrink();

      final currentRoute = _locationService?.activeRoute.value;
      final originalRoute = _locationService?.originalRoute;
      
      final routeToUse = originalRoute ?? currentRoute;
      List<int> floors = routeToUse?.floorsTraversed ?? [];
      
      if (floors.isEmpty) {
        final nearest = _locationService?.nearestStructure.value;
        if (nearest != null) {
          floors = _extractFloors(nearest);
        }
      }

      return Column(
        children: [
          FloatingActionButton.extended(
            heroTag: "btnStopNav",
            onPressed: _stopNavigation,
            backgroundColor: Colors.red[400],
            label: const Text(
              'Parar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(height: 12),

          if (floors.length > 1) ...[
            FloatingActionButton.extended(
              heroTag: "btnChooseFloor",
              onPressed: () => _showNavigationFloorDialog(floors),
              backgroundColor: Colors.blue[400],
              label: const Text(
                'Mudar Andar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.layers, color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    });
  }

  Widget _buildFloorSelectionButton() {
    return Obx(() {
      final isNavigating = _locationService?.isNavigating.value ?? false;
      final nearest = _locationService?.nearestStructure.value;

      if (isNavigating || nearest == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          heroTag: "btnSelectFloor",
          onPressed: _showFloorSelectionDialog,
          backgroundColor: Colors.orange[700],
          label: const Text(
            'Selecionar Andar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.layers, color: Colors.white),
        ),
      );
    });
  }

  Widget _buildSearchButton() {
    return FloatingActionButton(
      heroTag: "btnSearch",
      onPressed: () => setState(() => _showLocationSearch = !_showLocationSearch),
      backgroundColor: Colors.white,
      child: const Icon(Icons.search, color: Color(0xFF3C3CC0)),
    );
  }

  // ============ NAVEGAÇÃO ============

  /// Para navegação
  void _stopNavigation() {
    _locationService?.stopNavigation();
    Get.snackbar(
      'Navegação Cancelada',
      'A rota foi removida',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[400],
      colorText: Colors.white,
      icon: const Icon(Icons.cancel, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  /// Mostra dialog para mudar andar durante navegação
  Future<void> _showNavigationFloorDialog(List<int> floors) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Escolha o andar para navegação', style: TextStyle(color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: floors.map((floor) => ListTile(
            title: Text('Andar $floor', style: const TextStyle(color: Colors.black87, fontSize: 16)),
            onTap: () => Navigator.of(context).pop(floor),
          )).toList(),
        ),
      ),
    );

    if (selected != null) {
      await _updateNavigationFloor(selected);
    }
  }

  /// Atualiza andar da navegação
  Future<void> _updateNavigationFloor(int floor) async {
    if (floor == 0) {
      _locationService?.restoreFullRoute();
      _updateRoomsForFloor(floor);
      _showSnackBar('Exibindo rota completa');
      return;
    }

    final originalRoute = _locationService?.originalRoute;
    final currentRoute = _locationService?.activeRoute.value;
    
    final routeToUse = originalRoute ?? currentRoute;
    if (routeToUse == null) return;

    final floorSegments = routeToUse.segmentsForFloor(floor);
    
    if (floorSegments.isEmpty) {
      _showSnackBar('Nenhum segmento encontrado para o andar $floor');
      return;
    }

    final transitionSegments = routeToUse.segments
        .where((seg) => 
          seg.type == RouteSegmentType.transition && 
          (seg.floor == floor || seg.toFloor == floor || seg.fromFloor == floor)
        )
        .toList();

    final allSegments = <RouteSegment>[];
    
    for (final trans in transitionSegments) {
      if (trans.toFloor == floor && !allSegments.contains(trans)) {
        allSegments.add(trans);
      }
    }
    
    allSegments.addAll(floorSegments);
    
    for (final trans in transitionSegments) {
      if (trans.fromFloor == floor && !allSegments.contains(trans)) {
        allSegments.add(trans);
      }
    }

    final distance = allSegments.fold<double>(
      0.0, 
      (sum, seg) => sum + seg.distance
    );

    final currentDestination = routeToUse.destination;
    
    _locationService?.activeRoute.value = NavigationRoute(
      segments: allSegments,
      totalDistance: distance,
      estimatedTime: distance / 1.4 / 60, 
      destination: currentDestination,
      mode: routeToUse.mode,
      summary: routeToUse.summary,
    );

    _updateRoomsForFloor(floor);
    _showSnackBar('Exibindo rota do andar $floor');
  }

  /// Atualiza salas do andar selecionado
  void _updateRoomsForFloor(int floor) {
    final nearest = _locationService?.nearestStructure.value;
    final roomsByFloor = nearest?['roomsByFloor'] as Map<String, dynamic>?;
    
    _locationService?.roomsOnFloor.clear();
    
    if (roomsByFloor != null) {
      final floorKey = floor.toString();
      if (roomsByFloor.containsKey(floorKey) && roomsByFloor[floorKey] is List) {
        final rooms = roomsByFloor[floorKey] as List;
        if (rooms.isNotEmpty) {
          _locationService?.roomsOnFloor.assignAll(
            rooms.cast<Map<String, dynamic>>()
          );
        }
      }
    }
  }

  // ============ SELEÇÃO DE ANDAR (SEM NAVEGAÇÃO) ============

  Future<void> _showFloorSelectionDialog() async {
    final nearest = _locationService?.nearestStructure.value;

    if (nearest == null) {
      _showSnackBar('Você não está próximo de nenhuma estrutura');
      return;
    }

    final floors = _extractFloors(nearest);

    if (floors.isEmpty) {
      _showSnackBar('Estrutura sem andares disponíveis');
      return;
    }

    if (floors.length == 1) {
      _showSnackBar('Esta estrutura tem apenas o andar ${floors[0]}');
      return;
    }

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Escolha o andar', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: floors.map((floor) => ListTile(
            title: Text('Andar $floor', style: const TextStyle(color: Colors.black87, fontSize: 16)),
            onTap: () => Navigator.of(context).pop(floor),
          )).toList(),
        ),
      ),
    );

    if (selected != null) {
      await _selectFloor(selected, nearest);
    }
  }

  /// Seleciona andar e atualiza visualização (com ou sem localização)
  Future<void> _selectFloor(int floor, Map<String, dynamic> structure) async {
    // Atualiza rooms do andar selecionado
    _updateRoomsForFloorFromStructure(floor, structure);
    
    // Se tiver localização, notifica via WebSocket
    final position = _locationService?.currentPosition.value;
    if (position != null) {
      try {
        final ws = await _getWebSocket();
        ws?.sendPosition(
          position: [position.longitude, position.latitude],
          structureId: structure['id'],
          floor: floor,
        );
      } catch (e) {
        print('[HomePage] Erro ao enviar posição: $e');
      }
    }
    
    _showSnackBar('Exibindo andar $floor');
  }

  /// Atualiza rooms de um andar específico da estrutura
  void _updateRoomsForFloorFromStructure(int floor, Map<String, dynamic> structure) {
    final roomsByFloor = structure['roomsByFloor'] as Map<String, dynamic>?;
    
    _locationService?.roomsOnFloor.clear();
    
    if (roomsByFloor != null) {
      final floorKey = floor.toString();
      if (roomsByFloor.containsKey(floorKey) && roomsByFloor[floorKey] is List) {
        final rooms = roomsByFloor[floorKey] as List;
        if (rooms.isNotEmpty) {
          _locationService?.roomsOnFloor.assignAll(
            rooms.cast<Map<String, dynamic>>()
          );
        }
      }
    }
  }

  /// Obtém WebSocket
  Future<WebSocketService?> _getWebSocket() async {
    if (!Get.isRegistered<WebSocketService>()) {
      final ws = Get.put(WebSocketService());
      await ws.connect();
      return ws;
    }

    final ws = Get.find<WebSocketService>();
    if (!ws.isConnected.value) {
      await ws.connect();
    }
    return ws;
  }

  // ============ UTILITÁRIOS ============

  /// Card com informações da rota (distância e tempo)
  Widget _buildRouteInfoCard() {
    return Obx(() {
      final activeRoute = _locationService?.activeRoute.value;
      
      if (activeRoute == null) {
        return const SizedBox.shrink();
      }

      final distance = activeRoute.totalDistance;
      final timeMinutes = activeRoute.estimatedTime;
      final mode = activeRoute.mode;

      // Formata distância
      String distanceText;
      if (distance >= 1000) {
        distanceText = '${(distance / 1000).toStringAsFixed(2)} km';
      } else {
        distanceText = '${distance.toStringAsFixed(0)} m';
      }

      // Formata tempo
      String timeText;
      if (timeMinutes >= 60) {
        final hours = (timeMinutes / 60).floor();
        final minutes = (timeMinutes % 60).round();
        timeText = '${hours}h ${minutes}min';
      } else {
        timeText = '${timeMinutes.round()} min';
      }

      // Ícone e cor baseados no modo
      IconData modeIcon;
      Color modeColor;
      String modeText;
      
      if (mode == TransportMode.driving) {
        modeIcon = Icons.directions_car;
        modeColor = Colors.blue[700]!;
        modeText = 'Dirigindo';
      } else {
        modeIcon = Icons.directions_walk;
        modeColor = Colors.green[700]!;
        modeText = 'Caminhando';
      }

      return Positioned(
        bottom: _locationService?.isNavigating.value == true ? 200 : 100,
        left: 16,
        right: 16,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com modo de transporte
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(modeIcon, color: modeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      modeText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: modeColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C3CC0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ROTA ATIVA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3C3CC0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informações de distância e tempo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Distância
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.straighten,
                              color: Color(0xFF3C3CC0),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3C3CC0),
                              ),
                            ),
                            const Text(
                              'Distância',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tempo estimado
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              'Tempo Est.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  List<int> _extractFloors(Map<String, dynamic>? structure) {
    if (structure == null || structure['floors'] == null) return [];
    
    final floors = structure['floors'];
    if (floors is! List) return [];
    
    return List<int>.from(floors);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}