
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
          await locationService.fetchAndSetInternalRoute(
            structureId: structureId,
            roomId: roomId,
            floor: 0,
            end: [lat, lng],
          );
          print('[LocationSearch] Rota recebida: ${locationService.activeRoute.value?.steps}');
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
  final results = await LocationProvider().searchStructures(query);
      _searchResults.value = results;
    } catch (e) {
      print('Erro ao buscar: $e');
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
