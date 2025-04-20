import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService extends GetxService {
  final Rx<CameraPosition> initialPosition = Rx<CameraPosition>(
    const CameraPosition(
      target: LatLng(-23.550520, -46.633308),
      zoom: 17,
    ),
  );

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polygon> buildings = <Polygon>{}.obs;

  Future<MapService> init() async {
    await _loadMapData();
    return this;
  }

  Future<void> _loadMapData() async {
  }

  void updateCamera(CameraPosition position) {
  }

  Future<void> addMarker(LatLng position, String title) async {
  }
}
