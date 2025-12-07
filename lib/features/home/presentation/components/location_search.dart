import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/models/structure_model.dart';
import '../../../../data/models/navigation_model.dart';
import '../../../../data/providers/location_provider.dart' as provider;

class LocationSearch extends GetWidget<LocationService> {
  final _searchController = TextEditingController();
  final _results = <Structure>[].obs;
  final _isSearching = false.obs;
  final _provider = provider.LocationProvider();

  LocationSearch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(),
        Obx(() => _buildResults(context)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar salas, blocos, laboratórios...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_isSearching.value) {
      return _buildLoadingIndicator();
    }

    if (_results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(
        maxHeight: 300,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _results.length,
        itemBuilder: (context, index) => _buildResultItem(context, _results[index]),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, Structure structure) {
    final subtitle = _buildSubtitle(structure);
    final isDestination = _isCurrentDestination(structure);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDestination 
            ? const Color(0xFF3C3CC0) 
            : Theme.of(context).primaryColor,
        child: Icon(
          _getLocationIcon(structure.name),
          color: Colors.white,
        ),
      ),
      title: Text(
        structure.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDestination ? const Color(0xFF3C3CC0) : null,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: isDestination 
          ? const Icon(Icons.navigation, color: Color(0xFF3C3CC0))
          : null,
      onTap: () => _handleResultTap(context, structure),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _results.clear();
      return;
    }

    _isSearching.value = true;

    try {
      final results = await _provider.searchStructures(query);
      _results.value = results;
    } catch (e) {
      _showError('Não foi possível buscar estruturas');
    } finally {
      _isSearching.value = false;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _results.clear();
  }

  Future<void> _handleResultTap(BuildContext context, Structure structure) async {
    final parentContext = Scaffold.maybeOf(context)?.context ?? context;
    _clearSearch();

    if (!_isValidStructure(structure)) {
      _showError('Dados da estrutura inválidos');
      return;
    }

    // ✅ CORREÇÃO PRINCIPAL: Verificar se há localização disponível
    final hasLocation = controller.currentPosition.value != null;

    if (!hasLocation) {
      // Sem localização: apenas visualizar estrutura
      await _handleStructureVisualization(parentContext, structure);
      return;
    }

    // Com localização: calcular e navegar
    await _handleNavigationWithLocation(parentContext, structure);
  }

  /// ✨ NOVO: Lidar com visualização sem localização
  Future<void> _handleStructureVisualization(
    BuildContext context, 
    Structure structure
  ) async {
    // Perguntar se deseja apenas visualizar ou ativar localização
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_off, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Localização Desativada')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para navegar até ${structure.name}, é necessário ativar sua localização.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'O que deseja fazer?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('view'),
            child: const Text('Apenas Visualizar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop('enable'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.location_on),
            label: const Text('Ativar Localização'),
          ),
        ],
      ),
    );

    if (action == 'view') {
      // Visualizar estrutura sem navegação
      await _fetchStructureOnly(structure);
    } else if (action == 'enable') {
      // Tentar ativar localização
      final enabled = await _requestLocationPermission();
      if (enabled) {
        // Tentar navegar novamente
        await _handleNavigationWithLocation(context, structure);
      }
    }
  }

  /// ✨ NOVO: Buscar apenas informações da estrutura (sem rota)
  Future<void> _fetchStructureOnly(Structure structure) async {
    try {
      // Chama endpoint sem 'start' para obter apenas a estrutura
      final routeResponse = await _provider.getCompleteRoute(
        start: null, // SEM localização
        destinationRoomId: structure.id,
        mode: TransportMode.walking,
      );

      if (routeResponse == null) {
        _showError('Não foi possível carregar a estrutura');
        return;
      }

      // Salva estrutura e rooms
      if (routeResponse.structure != null) {
        final structureData = Map<String, dynamic>.from(routeResponse.structure!);
        
        if (routeResponse.roomsByFloor != null) {
          structureData['roomsByFloor'] = routeResponse.roomsByFloor;
        }
        
        controller.nearestStructure.value = structureData;

        // Carrega rooms do primeiro andar
        if (routeResponse.roomsByFloor != null) {
          final floors = (routeResponse.structure!['floors'] as List?)
              ?.cast<int>()
              .toList() ?? [];
          
          if (floors.isNotEmpty) {
            final firstFloor = floors.first;
            final floorKey = firstFloor.toString();
            final rooms = routeResponse.roomsByFloor![floorKey];
            
            if (rooms is List) {
              controller.roomsOnFloor.clear();
              controller.roomsOnFloor.assignAll(rooms?.cast<Map<String, dynamic>>() ?? []);
            }
          }
        }

        _showInfo(
          'Visualizando ${structure.name}',
          'Ative a localização para navegar',
        );
      }
    } catch (e) {
      print('[LocationSearch] Erro ao buscar estrutura: $e');
      _showError('Erro ao carregar estrutura: $e');
    }
  }

  /// Lidar com navegação quando há localização
  Future<void> _handleNavigationWithLocation(
    BuildContext context, 
    Structure structure
  ) async {
    if (controller.isNavigating.value) {
      final shouldReplace = await _confirmRouteReplacement(context);
      if (shouldReplace != true) return;
      
      controller.stopNavigation();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      await controller.fetchCompleteRoute(
        destinationRoomId: structure.id,
        mode: TransportMode.walking,
      );

      if (controller.activeRoute.value == null) {
        _showError('Não foi possível calcular a rota');
        return;
      }

      final shouldNavigate = await _confirmNavigation(context, structure);
      if (shouldNavigate == true) {
        controller.isNavigating.value = true;
        _showNavigationStarted();
      }
    } catch (e) {
      print('[LocationSearch] Erro ao calcular rota: $e');
      _showError('Erro ao calcular rota: $e');
    }
  }

  /// Solicita permissão de localização
  Future<bool> _requestLocationPermission() async {
    try {
      final permission = await controller.requestLocationPermission();
      return permission;
    } catch (e) {
      _showError('Erro ao ativar localização: $e');
      return false;
    }
  }

  Future<bool?> _confirmRouteReplacement(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rota em andamento'),
        content: const Text(
          'Deseja finalizar a rota atual e iniciar uma nova?',
        ),
               actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3CC0),
            ),
            child: const Text(
              'Sim, substituir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmNavigation(BuildContext context, Structure structure) {
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
            const Expanded(child: Text('Iniciar Navegação')),
          ],
        ),
        content: Text(
          'Deseja iniciar a navegação para ${structure.name}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não', style: TextStyle(color: Colors.grey)),
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

  bool _isValidStructure(Structure structure) {
    return structure.centroid != null &&
           structure.centroid!['coordinates'] != null &&
           structure.id > 0;
  }

  bool _isCurrentDestination(Structure structure) {
    final activeRoute = controller.activeRoute.value;
    return activeRoute?.destination == structure.id;
  }

  String _buildSubtitle(Structure structure) {
    final parts = <String>[];
    
    if (structure.floors != null && structure.floors!.isNotEmpty) {
      parts.add('Pisos: ${structure.floors!.join(", ")}');
    }
    
    return parts.join(' • ');
  }

  IconData _getLocationIcon(String name) {
    final n = name.toUpperCase();
    if (n.contains('ESCADA')) return Icons.stairs;
    if (n.contains('BANHEIRO')) return Icons.wc;
    if (n.contains('SECRETARIA') || n.contains('COORDENAÇÃO')) {
      return Icons.admin_panel_settings;
    }
    if (n.contains('BLOCO')) return Icons.apartment;
    if (n.contains('LAB') || n.contains('LABORAT')) return Icons.science;
    if (n.contains('SALA')) return Icons.meeting_room;
    if (n.contains('BPCF')) return Icons.local_hospital;
    return Icons.location_on;
  }

  void _showError(String message) {
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      duration: const Duration(seconds: 3),
    );
  }

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[900],
      icon: const Icon(Icons.info_outline, color: Colors.blue),
      duration: const Duration(seconds: 3),
    );
  }

  void _showNavigationStarted() {
    Get.snackbar(
      'Navegação Iniciada',
      'Siga a rota azul no mapa',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3C3CC0),
      colorText: Colors.white,
      icon: const Icon(Icons.navigation, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}