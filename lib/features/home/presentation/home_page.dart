import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../core/atoms/loading_screen.dart';
import '../../../data/services/location_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';


class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedLayer = 0;
  final List<String> _layerNames = [
    '1º Andar',
    '2º Andar',
    '3º Andar',
  ];

  bool _showLocationSearch = false;

  void _toggleLayer() {
    setState(() {
      _selectedLayer = (_selectedLayer + 1) % _layerNames.length;
    });
  }

  @override
  Widget build(BuildContext context) {
  final isVisitor = (Get.arguments != null && Get.arguments['visitor'] == true);

    LocationService? controller;
    try {
      controller = Get.find<LocationService>();
    } catch (e) {
      controller = null;
    }
    if (controller == null) {
      Future.microtask(() async {
        final loc = await Get.putAsync(() => LocationService().init());
        final hasPermission = await loc.requestLocationPermission();
        if (hasPermission == true) {
          await loc.getCurrentLocation();
        }
        setState(() {});
      });
      return const LoadingScreen(message: 'Carregando localização...');
    }
    Future.microtask(() async {
      final hasPermission = await controller?.requestLocationPermission();
      if (hasPermission == true) {
        await controller?.getCurrentLocation();
      }
    });
   
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: isVisitor
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.offAllNamed(AppRoutes.ACCESS_SELECTION),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
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
      ),
      drawer: isVisitor ? null : Sidebar(),
      body: Stack(
        children: [
          SizedBox.expand(
            child: MapWidget(
              zoom: 15.0,
              showUserLocation: true,
              selectedLayer: _selectedLayer,
            ),
          ),
          if (_showLocationSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LocationSearch(),
            ),
          // AVISO DE LOCALIZAÇÃO
          Obx(() {
            final position = controller?.currentPosition.value;
            if (position == null) {
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
                          'Localização não ativada. Para uma experiência completa, permita o acesso à localização.',
                          style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final permission = await controller?.requestLocationPermission();
                          if (permission == true) {
                            await controller?.getCurrentLocation();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(controller?.error.value ?? 'Permissão de localização negada.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Text('Ativar', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnSearch",
            onPressed: () {
              setState(() {
                _showLocationSearch = !_showLocationSearch;
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.search, color: Color(0xFF3C3CC0)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btnLayer",
            onPressed: _toggleLayer,
            backgroundColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers, color: Colors.blue),
                Text(_layerNames[_selectedLayer], style: TextStyle(fontSize: 10, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
