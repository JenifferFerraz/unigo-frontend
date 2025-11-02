import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import '../../../data/services/location_service.dart';
import 'animated_user_marker.dart';
import 'animated_route_layer.dart';

class MapWidget extends StatefulWidget {
  static LatLng? _selectedDestination;
  final double zoom;
  final bool showUserLocation;

  const MapWidget({
    Key? key,
    this.zoom = 13.0,
    this.showUserLocation = true,
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
              final roomName = room['name'] ?? '';
              final currentActiveRoute = locationService.activeRoute.value;
              final isDestination = currentActiveRoute?.destination != null && 
                                    room['id'] == currentActiveRoute?.destination;
              
              // Debug para verificar se está identificando a room de destino
              if (currentActiveRoute?.destination != null && room['id'] == currentActiveRoute?.destination) {
                print('[MapWidget] 🎯 Room de destino encontrada: ${room['name']} (ID: ${room['id']})');
              }
              
              if (geometry != null && geometry is Map && geometry['type'] == 'Polygon' && geometry['coordinates'] != null) {
                for (var ring in geometry['coordinates']) {
                  final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                  polygons.add(
                    Polygon(
                      points: points,
                      color: isDestination 
                          ? const Color(0xFF3C3CC0).withOpacity(0.4)
                          : const Color(0xFFededed),
                      borderColor: isDestination
                          ? const Color(0xFF3C3CC0)
                          : const Color(0xFFAAB9C9),
                      borderStrokeWidth: isDestination ? 4.0 : 1.2,
                      isFilled: true,
                    ),
                  );
                }
              }
              
              // Adicionar marcador de destino se for a room de destino
              if (isDestination && centroid != null && centroid is Map && centroid['type'] == 'Point' && centroid['coordinates'] != null) {
                markers.add(
                  Marker(
                    point: LatLng(centroid['coordinates'][1], centroid['coordinates'][0]),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C3CC0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3C3CC0).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              }
              
              // Adicionar nome da room (apenas texto, sem fundo)
              if (centroid != null && centroid is Map && centroid['type'] == 'Point' && centroid['coordinates'] != null && roomName.isNotEmpty) {
                markers.add(
                  Marker(
                    point: LatLng(centroid['coordinates'][1], centroid['coordinates'][0]),
                    width: 80,
                    height: 16,
                    child: Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isDestination ? const Color(0xFF3C3CC0) : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
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
            List<LatLng> uniqueRoutePoints = [];
            
            if (activeRoute != null) {
              List<LatLng> routePoints = [];
              if (activeRoute.steps.isNotEmpty) {
                routePoints = [
                  ...activeRoute.steps.expand((step) => [step.startPoint, step.endPoint])
                ];
              } else if (activeRoute.path != null && activeRoute.path!.isNotEmpty) {
                routePoints = activeRoute.path!;
              }
              
              for (final pt in routePoints) {
                if (pt != null && (uniqueRoutePoints.isEmpty || uniqueRoutePoints.last != pt)) {
                  uniqueRoutePoints.add(pt);
                }
              }
            }
            
            // Marcador para rotas com ponto único (ex: escada em andar intermediário)
            if (uniqueRoutePoints.length == 1) {
              markers.add(
                Marker(
                  point: uniqueRoutePoints[0],
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C3CC0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3C3CC0).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stairs,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              );
            }

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: center,
                zoom: widget.zoom,
                maxZoom: 22,
          
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                PolygonLayer(polygons: polygons),
                
                // Rota de navegação animada
                if (uniqueRoutePoints.length > 1)
                  AnimatedRouteLayer(routePoints: uniqueRoutePoints),
                
                MarkerLayer(markers: [
                  ...markers,
                  if (widget.showUserLocation && position != null)
                    Marker(
                      point: center,
                      width: 80,
                      height: 80,
                      child: const AnimatedUserMarker(),
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
