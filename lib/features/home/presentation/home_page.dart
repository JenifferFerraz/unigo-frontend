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

class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showLocationSearch = false;
  bool _isInitialized = false; // ← NOVA FLAG
  LocationService? _locationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Inicializa serviços necessários
  Future<void> _initializeServices() async {
    try {
      print('[HomePage] Iniciando serviços...');
      
      // 1. Garante WebSocket conectado
      await _ensureWebSocketConnected();
      
      // 2. Garante LocationService registrado
      await _initializeLocationService();
      
      // 3. Marca como inicializado
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      print('[HomePage] ✓ Serviços inicializados');
    } catch (e) {
      print('[HomePage] ❌ Erro ao inicializar serviços: $e');
      
      // Mesmo com erro, marca como inicializado para não travar
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
        print('[HomePage] Registrando WebSocketService...');
        final ws = Get.put(WebSocketService());
        await ws.connect();
      } else {
        final ws = Get.find<WebSocketService>();
        if (!ws.isConnected.value) {
          print('[HomePage] Reconectando WebSocket...');
          await ws.connect();
        }
      }
      print('[HomePage] ✓ WebSocket OK');
    } catch (e) {
      print('[HomePage] ⚠️ Erro no WebSocket (não crítico): $e');
    }
  }

  /// Inicializa LocationService
  Future<void> _initializeLocationService() async {
    try {
      if (Get.isRegistered<LocationService>()) {
        _locationService = Get.find<LocationService>();
        print('[HomePage] ✓ LocationService encontrado');
      } else {
        print('[HomePage] Registrando LocationService...');
        _locationService = Get.put(LocationService());
        
        // Só tenta obter localização se não for visitante
        if (!_isVisitor) {
          await _locationService?.requestLocationPermission();
        }
        
        print('[HomePage] ✓ LocationService registrado');
      }
    } catch (e) {
      print('[HomePage] ⚠️ Erro ao inicializar LocationService: $e');
      
      // Tenta criar um novo mesmo com erro
      try {
        _locationService = Get.put(LocationService(), permanent: false);
      } catch (e2) {
        print('[HomePage] ❌ Não foi possível criar LocationService: $e2');
      }
    }
  }

  /// Verifica se é visitante
  bool get _isVisitor {
    try {
      final authService = Get.find<AuthService>();
      return authService.currentUser.value == null ||
             (Get.arguments?['visitor'] == true);
    } catch (e) {
      print('[HomePage] Erro ao verificar visitante: $e');
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
        // Mapa
        const SizedBox.expand(
          child: MapWidget(zoom: 15.0, showUserLocation: true),
        ),

        // Busca de localização
        if (_showLocationSearch)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: LocationSearch(),
          ),

        // Banner de localização desativada
        _buildLocationBanner(),

        // Tab de feedback (apenas para visitantes)
        if (_isVisitor) const FeedbackTab(),
      ],
    );
  }

  /// Banner de localização desativada
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

        // Aguarda precisão adequada
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
        // Botões de navegação (quando navegando)
        _buildNavigationButtons(),

        // Botão de seleção de andar (quando não navegando)
        _buildFloorSelectionButton(),

        // Botão de busca
        _buildSearchButton(),
      ],
    );
  }

  /// Botões durante navegação
  Widget _buildNavigationButtons() {
    return Obx(() {
      final isNavigating = _locationService?.isNavigating.value ?? false;
      if (!isNavigating) return const SizedBox.shrink();

      // Usa APENAS os andares percorridos pela rota (floorsTraversed)
      // NÃO usa todos os andares da estrutura, apenas os que a rota realmente percorre
      final currentRoute = _locationService?.activeRoute.value;
      final originalRoute = _locationService?.originalRoute;
      
      // Prefere usar a rota original completa para ter os andares corretos
      final routeToUse = originalRoute ?? currentRoute;
      List<int> floors = routeToUse?.floorsTraversed ?? [];
      
      // Se não encontrou na rota, tenta na estrutura como fallback
      if (floors.isEmpty) {
        final nearest = _locationService?.nearestStructure.value;
        if (nearest != null) {
          floors = _extractFloors(nearest);
        }
      }

      return Column(
        children: [
          // Botão para parar navegação
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

          // Botão para mudar andar (multi-andar)
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

  /// Verifica se está visualizando um andar específico (rota filtrada)
  bool _isViewingSpecificFloor() {
    final route = _locationService?.activeRoute.value;
    if (route == null) return false;
    
    // Se a rota tem menos segmentos que o esperado para uma rota completa,
    // provavelmente está filtrada por andar
    // Uma rota completa geralmente tem: external + internal + transition + internal
    return route.segments.length < 3;
  }


  /// Botão de seleção de andar (quando não navegando)
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

  /// Botão de busca
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
        title: const Text('Escolha o andar para navegação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: floors.map((floor) => ListTile(
            title: Text('Andar $floor'),
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
    // Se for o térreo (0), restaura a rota completa
    // Caso contrário, mostra apenas a rota interna daquele andar
    if (floor == 0) {
      // Térreo: restaura a rota completa (externa + internas até o primeiro andar)
      _locationService?.restoreFullRoute();
      _updateRoomsForFloor(floor);
      _showSnackBar('Exibindo rota completa');
      return;
    }

    // Para outros andares: mostra apenas a rota interna daquele andar
    final originalRoute = _locationService?.originalRoute;
    final currentRoute = _locationService?.activeRoute.value;
    
    // Prefere usar a rota original completa para ter todos os segmentos
    final routeToUse = originalRoute ?? currentRoute;
    if (routeToUse == null) return;

    // Busca segmentos do andar na rota completa
    final floorSegments = routeToUse.segmentsForFloor(floor);
    
    if (floorSegments.isEmpty) {
      _showSnackBar('Nenhum segmento encontrado para o andar $floor');
      return;
    }

    // Inclui também segmentos de transição que conectam ao andar
    final transitionSegments = routeToUse.segments
        .where((seg) => 
          seg.type == RouteSegmentType.transition && 
          (seg.floor == floor || seg.toFloor == floor || seg.fromFloor == floor)
        )
        .toList();

    // Combina segmentos do andar com transições relevantes
    final allSegments = <RouteSegment>[];
    
    // Adiciona transições antes do andar
    for (final trans in transitionSegments) {
      if (trans.toFloor == floor && !allSegments.contains(trans)) {
        allSegments.add(trans);
      }
    }
    
    // Adiciona segmentos do andar
    allSegments.addAll(floorSegments);
    
    // Adiciona transições após o andar
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

    // Atualizar salas do andar
    _updateRoomsForFloor(floor);
    
    _showSnackBar('Exibindo rota do andar $floor');
  }

  /// Atualiza salas do andar selecionado
  void _updateRoomsForFloor(int floor) {
    final nearest = _locationService?.nearestStructure.value;
    final roomsByFloor = nearest?['roomsByFloor'] as Map<String, dynamic>?;
    
    // Limpa as salas primeiro para evitar desenhar salas de outros andares
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
        title: const Text('Escolha o andar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: floors.map((floor) => ListTile(
            title: Text('Andar $floor'),
            onTap: () => Navigator.of(context).pop(floor),
          )).toList(),
        ),
      ),
    );

    if (selected != null) {
      await _notifyFloorSelection(selected, nearest['id']);
    }
  }

  /// Notifica seleção de andar via WebSocket
  Future<void> _notifyFloorSelection(int floor, int structureId) async {
    final position = _locationService?.currentPosition.value;
    if (position == null) return;

    try {
      final ws = await _getWebSocket();
      ws?.sendPosition(
        position: [position.longitude, position.latitude],
        structureId: structureId,
        floor: floor,
      );
    } catch (e) {
      print('[HomePage] Erro ao enviar posição: $e');
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

  List<int> _extractFloors(Map<String, dynamic>? structure) {
    if (structure == null || structure['floors'] == null) return [];
    
    final floors = structure['floors'];
    if (floors is! List) return [];
    
    return List<int>.from(floors);
  }

  double _calculatePathDistance(List<LatLng> path) {
    double distance = 0.0;
    for (int i = 1; i < path.length; i++) {
      distance += Distance().as(LengthUnit.Meter, path[i - 1], path[i]);
    }
    return distance;
  }

  void _showSnackBar(String message) {
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