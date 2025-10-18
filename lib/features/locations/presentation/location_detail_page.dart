import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/structure_model.dart';
import '../../../data/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationDetailPage extends StatelessWidget {
  final Structure structure;

  const LocationDetailPage({Key? key, required this.structure}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(structure.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildLocationIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            structure.name,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${structure.id}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (structure.floors != null && structure.floors!.isNotEmpty)
                            const SizedBox(height: 8),
                          if (structure.floors != null && structure.floors!.isNotEmpty)
                            _buildInfoChips(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (structure.description != null && structure.description!.isNotEmpty)
              _buildInfoSection(
                context: context,
                title: 'Descrição',
                content: structure.description!,
                icon: Icons.description,
              ),


            const SizedBox(height: 16),

            if (structure.centroid != null && 
                structure.centroid!.coordinates != null &&
                structure.centroid!.coordinates!.length >= 2)
              _buildMap(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(context),
    );
  }

  Widget _buildLocationIcon() {
    IconData locationIcon = Icons.business;
    Color iconColor = Colors.indigo;

    
    return CircleAvatar(
      radius: 30,
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(
        locationIcon,
        size: 36,
        color: iconColor,
      ),
    );
  }

  Widget _buildInfoChips() {
    List<Widget> chips = [];

    if (structure.floors != null && structure.floors!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.stairs, size: 16),
          label: Text('Pisos: ${structure.floors!.join(", ")}'),
          backgroundColor: Colors.green[100],
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: chips,
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(content),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (structure.centroid?.coordinates == null || 
        structure.centroid!.coordinates!.length < 2) {
      return const SizedBox.shrink();
    }

    // GeoJSON coordinates are [longitude, latitude]
    final longitude = structure.centroid!.coordinates![0];
    final latitude = structure.centroid!.coordinates![1];
    final latLng = LatLng(latitude, longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.map, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Localização no Mapa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              options: MapOptions(
                center: latLng,
                zoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: latLng,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final hasCoordinates = structure.centroid?.coordinates != null && 
                          structure.centroid!.coordinates!.length >= 2;

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (hasCoordinates)
              ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Navegar'),
                onPressed: () => _openMaps(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
              onPressed: () => _shareLocation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMaps() async {
    if (structure.centroid?.coordinates != null && 
        structure.centroid!.coordinates!.length >= 2) {
      final longitude = structure.centroid!.coordinates![0];
      final latitude = structure.centroid!.coordinates![1];
      final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Erro',
          'Não foi possível abrir o mapa',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _shareLocation() {
    final String locationInfo = '''
${structure.name} (ID: ${structure.id})
${structure.description ?? ''}

Compartilhado via UniGo
    ''';
    
    Get.snackbar(
      'Compartilhar',
      'Funcionalidade em desenvolvimento',
      snackPosition: SnackPosition.BOTTOM,
      messageText: Text(locationInfo),
    );
  }
}