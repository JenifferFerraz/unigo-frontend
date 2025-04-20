import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import '../../../data/services/location_service.dart';

class MapWidget extends StatelessWidget {
  final LocationService locationService = Get.find<LocationService>();
  final double zoom;
  final bool showUserLocation;

  MapWidget({
    Key? key,
    this.zoom = 13.0,
    this.showUserLocation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final position = locationService.currentPosition.value;
      final center = position != null
          ? LatLng(position.latitude, position.longitude)
          : LatLng(-23.550520, -46.633308); 

      return FlutterMap(
        options: MapOptions(
          center: center,
          zoom: zoom,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          if (showUserLocation && position != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }
}
