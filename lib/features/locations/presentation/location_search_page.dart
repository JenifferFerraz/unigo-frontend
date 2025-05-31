import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../../../data/models/location_model.dart';
import 'location_detail_page.dart';

class LocationSearchPage extends StatelessWidget {
  final LocationController controller = Get.put(LocationController());
  final TextEditingController searchController = TextEditingController();

  LocationSearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Localização'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar salas, blocos, laboratórios...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.clearFilters();
                  },
                ),
              ),
              onChanged: (value) {
                controller.searchQuery.value = value;
                if (value.isNotEmpty) {
                  controller.fetchLocations();
                }
              },
            ),
          ),

          // Chips de filtros aplicados
          Obx(() {
            List<Widget> filterChips = [];
            
            if (controller.selectedType.isNotEmpty) {
              filterChips.add(
                Chip(
                  label: Text(controller.selectedType.value),
                  onDeleted: () {
                    controller.selectedType.value = '';
                    controller.fetchLocations();
                  },
                ),
              );
            }
            
            if (controller.selectedBlock.isNotEmpty) {
              filterChips.add(
                Chip(
                  label: Text('Bloco ${controller.selectedBlock.value}'),
                  onDeleted: () {
                    controller.selectedBlock.value = '';
                    controller.fetchLocations();
                  },
                ),
              );
            }
            
            if (controller.selectedFloor.value > 0) {
              filterChips.add(
                Chip(
                  label: Text('Piso ${controller.selectedFloor.value}'),
                  onDeleted: () {
                    controller.selectedFloor.value = 0;
                    controller.fetchLocations();
                  },
                ),
              );
            }
            
            if (filterChips.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: filterChips,
              ),
            );
          }),

          // Lista de resultados
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.error.isNotEmpty) {
                return Center(child: Text(controller.error.value));
              }
              
              if (controller.locations.isEmpty) {
                return const Center(
                  child: Text('Nenhum local encontrado. Tente outra busca.'),
                );
              }
              
              return ListView.builder(
                itemCount: controller.locations.length,
                itemBuilder: (context, index) {
                  final location = controller.locations[index];
                  return _buildLocationItem(context, location);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // Item de localização na lista
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(locationIcon, color: Colors.white),
        ),
        title: Text(
          '${location.name} (${location.code})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        onTap: () => Get.to(() => LocationDetailPage(location: location)),
      ),
    );
  }

  // Diálogo de filtros
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filtro por tipo
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  value: controller.selectedType.value.isEmpty ? null : controller.selectedType.value,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos os tipos')),
                    ...controller.locationTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_formatLocationType(type)),
                    )),
                  ],
                  onChanged: (value) {
                    controller.selectedType.value = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                
                // Filtro por bloco
                Obx(() => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Bloco'),
                  value: controller.selectedBlock.value.isEmpty ? null : controller.selectedBlock.value,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos os blocos')),
                    ...controller.blocks.map((block) => DropdownMenuItem(
                      value: block,
                      child: Text('Bloco $block'),
                    )),
                  ],
                  onChanged: (value) {
                    controller.selectedBlock.value = value ?? '';
                  },
                )),
                const SizedBox(height: 16),
                
                // Filtro por andar
                TextField(
                  decoration: const InputDecoration(labelText: 'Piso'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: controller.selectedFloor.value > 0 
                        ? controller.selectedFloor.value.toString() 
                        : ''
                  ),
                  onChanged: (value) {
                    controller.selectedFloor.value = int.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clearFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.fetchLocations();
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  // Formata os tipos de localização para exibição
  String _formatLocationType(String type) {
    switch (type) {
      case 'classroom':
        return 'Sala de Aula';
      case 'laboratory':
        return 'Laboratório';
      case 'library':
        return 'Biblioteca';
      case 'cafeteria':
        return 'Cantina';
      case 'auditorium':
        return 'Auditório';
      case 'block':
        return 'Bloco';
      case 'building':
        return 'Prédio';
      case 'administrative':
        return 'Administrativo';
      default:
        return 'Outro';
    }
  }
}
