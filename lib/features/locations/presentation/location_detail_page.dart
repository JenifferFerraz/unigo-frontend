import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/location_model.dart';
import '../../../data/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationDetailPage extends StatelessWidget {
  final Location location;
  final LocationService _locationService = Get.find<LocationService>();

  LocationDetailPage({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com código e tipo
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código: ${location.code}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatLocationType(location.type),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        _buildLocationIcon(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoChips(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            if (location.description != null && location.description!.isNotEmpty)
              _buildInfoSection(
                context: context,
                title: 'Descrição',
                content: location.description!,
                icon: Icons.description,
              ),

            // Pontos de referência
            if (location.nearbyLandmarks != null && location.nearbyLandmarks!.isNotEmpty)
              _buildInfoSection(
                context: context,
                title: 'Pontos de Referência',
                content: location.nearbyLandmarks!,
                icon: Icons.place,
              ),

            // Notas de acessibilidade
            if (location.accessibilityNotes != null && location.accessibilityNotes!.isNotEmpty)
              _buildInfoSection(
                context: context,
                title: 'Informações de Acessibilidade',
                content: location.accessibilityNotes!,
                icon: Icons.accessible,
              ),

            const SizedBox(height: 16),

            // Mapa se houver coordenadas
            if (location.latitude != null && location.longitude != null)
              _buildMap(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(context),
    );
  }

  // Constrói ícone específico para o tipo de localização
  Widget _buildLocationIcon() {
    IconData locationIcon;
    Color iconColor;

    switch (location.type) {
      case 'classroom':
        locationIcon = Icons.class_;
        iconColor = Colors.blue;
        break;
      case 'laboratory':
        locationIcon = Icons.science;
        iconColor = Colors.green;
        break;
      case 'library':
        locationIcon = Icons.menu_book;
        iconColor = Colors.brown;
        break;
      case 'cafeteria':
        locationIcon = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'auditorium':
        locationIcon = Icons.event_seat;
        iconColor = Colors.purple;
        break;
      case 'block':
      case 'building':
        locationIcon = Icons.business;
        iconColor = Colors.indigo;
        break;
      default:
        locationIcon = Icons.location_on;
        iconColor = Colors.red;
    }

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

  // Constrói chips de informação (bloco, andar)
  Widget _buildInfoChips() {
    List<Widget> chips = [];

    if (location.block != null && location.block!.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.business, size: 16),
          label: Text('Bloco ${location.block}'),
          backgroundColor: Colors.blue[100],
        ),
      );
    }

    if (location.floor != null) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.stairs, size: 16),
          label: Text('Piso ${location.floor}'),
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

  // Constrói uma seção de informações
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

  // Constrói o mapa se houver coordenadas
  Widget _buildMap() {
    if (location.latitude == null || location.longitude == null) {
      return const SizedBox.shrink();
    }

    final latLng = LatLng(location.latitude!, location.longitude!);

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
                  markers: [                    Marker(
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

  // Botões de navegação e compartilhamento
  Widget _buildNavigationButtons(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (location.latitude != null && location.longitude != null)
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

  // Abre o Google Maps para navegação
  void _openMaps() async {
    if (location.latitude != null && location.longitude != null) {
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        Get.snackbar(
          'Erro',
          'Não foi possível abrir o mapa',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  // Compartilha informações da localização
  void _shareLocation() {
    final String locationInfo = '''
    ${location.name} (${location.code})
    ${_formatLocationType(location.type)}
    ${location.block != null ? 'Bloco ${location.block}' : ''}
    ${location.floor != null ? 'Piso ${location.floor}' : ''}
    
    Compartilhado via UniGo
    ''';
    
    // Usar plugin de compartilhamento aqui
    Get.snackbar(
      'Compartilhar',
      'Funcionalidade em desenvolvimento',
      snackPosition: SnackPosition.BOTTOM,
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
