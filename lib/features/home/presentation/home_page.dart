import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../data/services/location_service.dart';
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
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
      drawer: Sidebar(),
      body: Stack(
        children: [
          Expanded(
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
        onPressed: () => controller.getCurrentLocation(),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
