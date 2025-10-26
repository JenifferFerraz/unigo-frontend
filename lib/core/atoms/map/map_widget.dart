import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import '../../../data/services/location_service.dart';

class MapWidget extends StatefulWidget {
  static LatLng? _selectedDestination;
  final double zoom;
  final bool showUserLocation;
  final int selectedLayer;

  const MapWidget({
    Key? key,
    this.zoom = 13.0,
    this.showUserLocation = true,
    this.selectedLayer = 0,
  }) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();

  }

class _MapWidgetState extends State<MapWidget> {
  LocationService get locationService => Get.find<LocationService>();
  final MapController _mapController = MapController();
  bool _hasCenteredOnce = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final rooms = locationService.roomsOnFloor;
            final List<Polygon> polygons = [];
            final List<Marker> markers = [];

            final nearest = locationService.nearestStructure.value;
            if (nearest != null && nearest['geometry'] != null && nearest['geometry']['type'] == 'Polygon') {
              for (var ring in nearest['geometry']['coordinates']) {
                final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                polygons.add(
                  Polygon(
                    points: points,
                    color: const Color(0xFFededed),
                    borderColor: const Color(0xFFAAB9C9),
                    borderStrokeWidth: 4,
                     isFilled: true,
                  ),
                );
              }
            }

 
            for (final room in rooms) {
              final geometry = room['geometry'];
              final centroid = room['centroid'];
              if (geometry['type'] == 'Polygon') {
                for (var ring in geometry['coordinates']) {
                  final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                  polygons.add(
                    Polygon(
                      points: points,
                      color: const Color(0xFFededed),
                      borderColor: const Color(0xFFAAB9C9),
                      borderStrokeWidth: 1.2,
                    ),
                  );
                }
              }
              if (centroid != null && centroid['type'] == 'Point') {
                markers.add(
                  Marker(
                    point: LatLng(centroid['coordinates'][1], centroid['coordinates'][0]),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: const Color(0xFFAAB9C9), size: 30),
                  ),
                );
              }
            }

            final position = locationService.currentPosition.value;
            final activeRoute = locationService.activeRoute.value;
            final center = position != null
                ? LatLng(position.latitude, position.longitude)
                : LatLng(-16.294387, -48.944379);

            if (position != null && !_hasCenteredOnce) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  _mapController.move(center, widget.zoom);
                } catch (e) {
                  print('[MapWidget] erro ao mover o mapa (postFrame): $e');
                }
              });
              _hasCenteredOnce = true;
            }

            final List<Polyline> allPolylines = [];
            if (activeRoute != null) {
              List<LatLng> routePoints = [];
              if (activeRoute.steps.isNotEmpty) {
                routePoints = [
                  ...activeRoute.steps.expand((step) => [step.startPoint, step.endPoint])
                ];
              } else if (activeRoute.path != null && activeRoute.path!.isNotEmpty) {
                routePoints = activeRoute.path!;
              }
              final List<LatLng> uniqueRoutePoints = [];
              for (final pt in routePoints) {
                if (pt != null && (uniqueRoutePoints.isEmpty || uniqueRoutePoints.last != pt)) {
                  uniqueRoutePoints.add(pt);
                }
              }
              if (uniqueRoutePoints.isNotEmpty) {
                allPolylines.add(
                  Polyline(
                    points: uniqueRoutePoints,
                    color: Colors.blue, // cor sólida
                    strokeWidth: 8.0,
                    borderStrokeWidth: 0.0, // sem fundo
                    borderColor: Colors.transparent, // sem fundo
                    isDotted: false,
                    strokeCap: StrokeCap.round,
                  ),
                );
              }
            }

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: center,
                zoom: widget.zoom,
                maxZoom: 22,
                // Removido onTap e onDoubleTap para desabilitar seleção de destino
                // onTap: null,
                // onDoubleTap: null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: allPolylines),
                MarkerLayer(markers: [
                  ...markers,
                  if (widget.showUserLocation && position != null)
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (MapWidget._selectedDestination != null)
                    Marker(
                      point: MapWidget._selectedDestination!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                ]),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Map tiles by Stamen, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
            style: TextStyle(fontSize: 12, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  }
