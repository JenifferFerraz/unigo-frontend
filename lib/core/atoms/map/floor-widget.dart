import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/location_service.dart';
import '../../../data/models/navigation_model.dart';

/// Widget para selecionar andar durante navegação multi-andar
class FloorSelectorWidget extends StatelessWidget {
  const FloorSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationService = Get.find<LocationService>();

    return Obx(() {
      final activeRoute = locationService.activeRoute.value;
      
      // Não exibe se não há rota ativa
      if (activeRoute == null) return const SizedBox.shrink();
      
      final floors = activeRoute.floorsTraversed;
      
      // Não exibe se há apenas um andar
      if (floors.length <= 1) return const SizedBox.shrink();

      return Positioned(
        right: 16,
        top: 100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF3C3CC0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Andares',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de andares (invertida: maior no topo)
              ...floors.reversed.map((floor) => _buildFloorButton(
                floor,
                locationService,
                floors,
              )),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFloorButton(
    int floor,
    LocationService locationService,
    List<int> allFloors,
  ) {
    return Obx(() {
      final activeRoute = locationService.activeRoute.value;
      if (activeRoute == null) return const SizedBox.shrink();

      // Determina se é o andar atual
      final currentFloor = _getCurrentFloor(locationService);
      final isCurrentFloor = currentFloor == floor;
      
      // Verifica se é o andar do destino
      final isDestinationFloor = _isDestinationFloor(activeRoute, floor);

      return InkWell(
        onTap: () => _changeFloor(floor, locationService),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isCurrentFloor 
                ? const Color(0xFF3C3CC0).withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              bottom: floor != allFloors.first 
                  ? BorderSide(color: Colors.grey.shade300, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícone e número do andar
              Row(
                children: [
                  Icon(
                    _getFloorIcon(floor),
                    size: 18,
                    color: isCurrentFloor 
                        ? const Color(0xFF3C3CC0)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    floor == 0 ? 'T' : '$floor°',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrentFloor ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentFloor 
                          ? const Color(0xFF3C3CC0)
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              
              // Indicador de destino
              if (isDestinationFloor)
                const Icon(
                  Icons.flag,
                  size: 16,
                  color: Color(0xFF3C3CC0),
                ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getFloorIcon(int floor) {
    if (floor == 0) return Icons.store;
    return Icons.apartment;
  }

  int? _getCurrentFloor(LocationService locationService) {
    final activeRoute = locationService.activeRoute.value;
    if (activeRoute == null) return null;

    final floorsTraversed = activeRoute.floorsTraversed;
    if (floorsTraversed.isNotEmpty) {
      return floorsTraversed.first;
    }

    return null;
  }

  bool _isDestinationFloor(NavigationRoute route, int floor) {
    // Verifica se o destino está neste andar
    final internalSegments = route.segments
        .where((seg) => seg.type == RouteSegmentType.internal && seg.floor == floor)
        .toList();
    
    if (internalSegments.isEmpty) return false;
    
    // Verifica se há segmento com descrição de destino
    return internalSegments.any((seg) => 
      seg.description.toLowerCase().contains('destino')
    );
  }

  void _changeFloor(int targetFloor, LocationService locationService) {
    print('[FloorSelector] 🔄 Mudando para andar $targetFloor');
    
    final activeRoute = locationService.activeRoute.value;
    if (activeRoute == null) return;

    // Obtém a estrutura atual
    final nearest = locationService.nearestStructure.value;
    final roomsByFloor = nearest?['roomsByFloor'] as Map<String, dynamic>?;
    
    if (roomsByFloor == null) {
      print('[FloorSelector] ⚠️ roomsByFloor não disponível');
      return;
    }

    // Carrega rooms do andar selecionado
    final floorKey = targetFloor.toString();
    final rooms = roomsByFloor[floorKey];
    
    if (rooms is List) {
      // Filtra rooms do andar específico
      final filteredRooms = rooms
          .where((room) {
            final roomFloor = room['floor'];
            return roomFloor != null && roomFloor == targetFloor;
          })
          .toList();
      
      locationService.roomsOnFloor.clear();
      locationService.roomsOnFloor.assignAll(filteredRooms.cast<Map<String, dynamic>>());
      
      print('[FloorSelector] ✅ Carregados ${filteredRooms.length} rooms do andar $targetFloor');
      
      // Mostra snackbar de confirmação
      Get.snackbar(
        'Andar $targetFloor',
        'Exibindo rota do andar $targetFloor',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF3C3CC0),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.layers, color: Colors.white),
      );
    }
  }
}