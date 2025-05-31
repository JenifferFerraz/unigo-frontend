import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../data/services/location_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';

class HomePage extends GetView<LocationService> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Get.toNamed(AppRoutes.CLASS_NOTIFICATIONS),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
      drawer: Sidebar(),      body: Stack(
        children: [
          SizedBox.expand(
            child: MapWidget(
              zoom: 15.0,
              showUserLocation: true,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: LocationSearch(),
          ),    
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btnLocation",
        onPressed: () => controller.getCurrentLocation(),
        child: const Icon(Icons.my_location),
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
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
