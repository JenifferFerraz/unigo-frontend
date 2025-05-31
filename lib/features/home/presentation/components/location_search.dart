import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/models/location_model.dart';
import '../../../locations/presentation/location_detail_page.dart';
import '../../../../routes/app_routes.dart';

class LocationSearch extends GetWidget<LocationService> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<Location> _searchResults = <Location>[].obs;
  final RxBool _isSearching = false.obs;
  
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
              prefixIcon: const Icon(Icons.search),              suffixIcon: IconButton(
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
        
        // Resultados da pesquisa
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
    );  }

  Widget _buildLocationItem(BuildContext context, Location location) {
    final String subtitle = [
      if (location.block != null) 'Bloco ${location.block}',
      if (location.floor != null) 'Piso ${location.floor}',
    ].join(' • ');

    IconData locationIcon;
    switch (location.type) {
      case 'classroom':
        locationIcon = Icons.class_;
        break;
      case 'laboratory':
        locationIcon = Icons.science;
        break;
      case 'library':
        locationIcon = Icons.menu_book;
        break;
      case 'cafeteria':
        locationIcon = Icons.restaurant;
        break;
      case 'auditorium':
        locationIcon = Icons.event_seat;
        break;
      case 'block':
      case 'building':
        locationIcon = Icons.business;
        break;
      default:
        locationIcon = Icons.location_on;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(locationIcon, color: Colors.white),
      ),
      title: Text(
        '${location.name} (${location.code})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      onTap: () {
        _searchResults.clear();
        _searchController.clear();
        Get.to(() => LocationDetailPage(location: location));
      },
    );
  }

  // Realizar pesquisa na API
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }
    
    _isSearching.value = true;
    
    try {
      print('Starting location search for query: $query');
      final results = await controller.searchLocations(query);
      print('Search returned ${results.length} results');
      _searchResults.value = results;
    } catch (e) {
      print('Search error: $e');
      String errorMessage = 'Não foi possível realizar a busca';
      
      if (e.toString().contains('No authentication token found')) {
        errorMessage = 'Você precisa estar logado para realizar buscas';
      } else if (e.toString().contains('Failed to search locations: 401')) {
        errorMessage = 'Sua sessão expirou. Por favor, faça login novamente';
      }
      
      Get.snackbar(
        'Erro', 
        errorMessage,
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
