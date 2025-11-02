
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/models/structure_model.dart';
import '../../../../data/providers/location_provider.dart';
import '../../../locations/presentation/location_detail_page.dart';
import '../../../../routes/app_routes.dart';

class LocationSearch extends GetWidget<LocationService> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<Structure> _searchResults = <Structure>[].obs;
  final RxBool _isSearching = false.obs;
  IconData getLocationIcon(String name) {
  final n = name.toUpperCase();
  if (n.contains('ESCADA')) return Icons.stairs;
  if (n.contains('BANHEIRO')) return Icons.wc;
  if (n.contains('SECRETARIA') || n.contains('COORDENAÇÃO')) return Icons.admin_panel_settings;
  if (n.contains('BLOCO')) return Icons.apartment;
  if (n.contains('LAB') || n.contains('LABORAT')) return Icons.science;
  if (n.contains('SALA')) return Icons.meeting_room;
  if (n.contains('BPCF')) return Icons.local_hospital;
  return Icons.location_on;
}
  LocationSearch({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                onPressed: () {
                  _searchController.clear();
                  _searchResults.clear();
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onChanged: _performSearch,
          ),
        ),
        Obx(() {
          if (_isSearching.value) {
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
          if (_searchResults.isNotEmpty) {
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
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return _buildLocationItem(context, location);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildLocationItem(BuildContext context, Structure structure) {
    final String subtitle = [
      if (structure.floors != null) 'Pisos: ${structure.floors!.join(", ")}',
    ].join(' • ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(getLocationIcon(structure.name), color: Colors.white),
      ),
      title: Text(
        structure.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      onTap: () async {
        _searchResults.clear();
        _searchController.clear();
        
        final coords = structure.centroid != null && structure.centroid['coordinates'] != null
            ? structure.centroid['coordinates']
            : null;
        final int? roomId = structure.id;
        final int? structureId = structure.structureId;
        
        
        if (coords != null && coords.length >= 2 && structureId != null) {
          final double lat = coords[1];
          final double lng = coords[0];
          final locationService = Get.find<LocationService>();
          
          
          int startFloor = 0; 
          
          final userPos = locationService.currentPosition.value;
          final nearestStructure = locationService.nearestStructure.value;
          
          
          if (userPos != null && nearestStructure != null && nearestStructure['id'] == structureId) {
            final floors = structure.floors ?? [0];
            if (floors.length > 1) {
              final selected = await showDialog<int>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Em qual andar você está?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: floors.map((floor) => ListTile(
                      title: Text('Andar $floor'),
                      onTap: () => Navigator.of(ctx).pop(floor),
                    )).toList(),
                  ),
                ),
              );
              if (selected != null) {
                startFloor = selected;
              } else {
                return;
              }
            } else if (floors.isNotEmpty) {
              startFloor = floors[0];
            }
          }
          
          if (locationService.isNavigating.value) {
            final shouldReplace = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Rota em andamento'),
                content: const Text(
                  'Você já está navegando para outro destino. Deseja finalizar a rota atual e iniciar uma nova?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C3CC0),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sim, substituir'),
                  ),
                ],
              ),
            );
            
            if (shouldReplace != true) {
              return; 
            }
            
            // Parar navegação atual
            locationService.stopNavigation();
            
            // Aguardar um frame para garantir limpeza
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          print('[LocationSearch] 🛣️ Buscando rota: structureId=$structureId, floor=$startFloor, roomId=$roomId');
          
          await locationService.fetchAndSetInternalRoute(
            structureId: structureId,
            roomId: roomId,
            floor: startFloor,
            end: [lat, lng],
          );
          print('[LocationSearch] ✓ Rota recebida do andar $startFloor: ${locationService.activeRoute.value?.steps.length} steps');
          print('[LocationSearch] ✓ Path points: ${locationService.activeRoute.value?.path?.length}');
          
          // Mostra diálogo perguntando se quer iniciar navegação
          final shouldNavigate = await showDialog<bool>(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Sim, navegar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          
          if (shouldNavigate == true) {
            locationService.isNavigating.value = true;
            Get.snackbar(
              'Navegação Iniciada',
              'Siga a rota azul no mapa',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF3C3CC0),
              colorText: Colors.white,
              icon: const Icon(Icons.navigation, color: Colors.white),
              duration: const Duration(seconds: 3),
            );
          } else {
            print('[LocationSearch] ❌ Usuário cancelou navegação');
          }
        } else {
          print('[LocationSearch] ⚠️ Dados inválidos: coords=${coords?.length}, structureId=$structureId');
        }
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }
    _isSearching.value = true;
    try {
      print('[LocationSearch] 🔍 Buscando: $query');
      final results = await LocationProvider().searchStructures(query);
      print('[LocationSearch] ✓ Encontrados ${results.length} resultados');
      _searchResults.value = results;
    } catch (e) {
      print('[LocationSearch] ❌ Erro ao buscar: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível buscar estruturas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isSearching.value = false;
    }
  }
}
