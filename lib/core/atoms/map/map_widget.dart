import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../data/services/location_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapWidget extends StatelessWidget {
  // Estado para destino selecionado
  static LatLng? _selectedDestination;
  LocationService get locationService => Get.find<LocationService>();
  final double zoom;
  final bool showUserLocation;
  final int selectedLayer;

  const MapWidget({
    Key? key,
    this.zoom = 13.0,
    this.showUserLocation = true,
    this.selectedLayer = 0,
  }) : super(key: key);

  Future<Map<String, dynamic>> loadGeoJson(String file) async {
    final geojsonStr = await rootBundle.loadString(file);
    return json.decode(geojsonStr);
  }

  @override
  Widget build(BuildContext context) {
    final geojsonFiles = [
      'assets/geojson/Bloco-H-1-Andar.geojson',
      'assets/geojson/Bloco-H-2-Andar.geojson',
      'assets/geojson/Bloco-H-3-Andar.geojson',
    ];

    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(geojsonFiles.map(loadGeoJson)),
            builder: (context, snapshot) {
              final geojsons = snapshot.data ?? [];
              final colors = [Colors.red, Colors.green, Colors.blue];

              final int i = selectedLayer % geojsons.length;
              final geojson = geojsons.isNotEmpty ? geojsons[i] : null;
              final color = colors[i % colors.length];
              final List<Marker> markers = [];
              final List<Polygon> polygons = [];
              final List<Polyline> polylines = [];

              if (geojson != null) {
                for (var feature in geojson['features']) {
                  final type = feature['geometry']['type'];
                  final coords = feature['geometry']['coordinates'];
                  final props = feature['properties'] ?? {};
                  final pinName = props['name'] ?? '';
                  if (type == 'Point') {
                    markers.add(
                      Marker(
                        point: LatLng(coords[1], coords[0]),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Local'),
                                content: Text(pinName),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text('Fechar'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(Icons.location_on, color: color, size: 30),
                        ),
                      ),
                    );
                  } else if (type == 'Polygon') {
                    for (var ring in coords) {
                      final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                      polygons.add(
                        Polygon(
                          points: points,
                          color: color.withOpacity(0.3),
                          borderColor: color,
                          borderStrokeWidth: 2,
                        ),
                      );
                    }
                  } else if (type == 'MultiPolygon') {
                    for (var poly in coords) {
                      for (var ring in poly) {
                        final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                        polygons.add(
                          Polygon(
                            points: points,
                            color: color.withOpacity(0.3),
                            borderColor: color,
                            borderStrokeWidth: 2,
                          ),
                        );
                      }
                    }
                  } else if (type == 'LineString') {
                    final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                    polylines.add(
                      Polyline(
                        points: points,
                        color: color,
                        strokeWidth: 3,
                      ),
                    );
                  } else if (type == 'MultiLineString') {
                    for (var line in coords) {
                      final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
                      polylines.add(
                        Polyline(
                          points: points,
                          color: color,
                          strokeWidth: 3,
                        ),
                      );
                    }
                  }
                }
              }

              return Obx(() {
                final position = locationService.currentPosition.value;
                print('[MapWidget] currentPosition: $position');
                final center = position != null
                    ? LatLng(position.latitude, position.longitude)
                    : LatLng(-16.294387, -48.944379);
                print('[MapWidget] center usado no mapa: $center');
                return FlutterMap(
                  options: MapOptions(
                    center: center,
                    zoom: zoom,
                    maxZoom: 22,
                    onTap: (tapPos, latlng) {
                      _selectedDestination = latlng;
                      // Força rebuild
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.app',
                    ),
                    PolygonLayer(polygons: polygons),
                    PolylineLayer(polylines: polylines),
                    MarkerLayer(markers: [
                      ...markers,
                      if (showUserLocation && position != null)
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
                      if (_selectedDestination != null)
                        Marker(
                          point: _selectedDestination!,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                    ]),
                  ],
                );
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Map tiles by Stamen, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  }
