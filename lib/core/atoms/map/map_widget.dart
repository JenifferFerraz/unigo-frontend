import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/services/location_service.dart';
import '../../../data/models/navigation_model.dart';
import 'animated_user_marker.dart';
import 'animated_route_layer.dart';

class MapWidget extends StatefulWidget {
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
  final _mapController = MapController();
  bool _hasCenteredOnce = false;

  LocationService get _locationService => Get.find<LocationService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMap()),
        _buildAttribution(),
      ],
    );
  }

  Widget _buildMap() {
    return Obx(() {
      final position = _locationService.currentPosition.value;
      final center = _getCenterPosition(position);

      _centerMapOnce(center);

      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.zoom,
          maxZoom: 22,
        ),
        children: [
          _buildTileLayer(),
          _buildPolygonLayer(),
          _buildRouteLayer(),
          _buildMarkerLayer(center, position),
        ],
      );
    });
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.example.app',
    );
  }

  Widget _buildPolygonLayer() {
    final polygons = <Polygon>[
      ..._buildStructurePolygons(),
      ..._buildRoomPolygons(),
    ];

    return PolygonLayer(polygons: polygons);
  }

  /// 🔥 CORREÇÃO: Layer de rota com TODOS os pontos (curvas)
  Widget _buildRouteLayer() {
    final routePoints = _getRoutePointsForCurrentFloor();

    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }


    return AnimatedRouteLayer(routePoints: routePoints);
  }

  Widget _buildMarkerLayer(LatLng center, Position? position) {
    final markers = <Marker>[
      ..._buildRoomMarkers(),
      ..._buildStairsMarkers(),
      if (widget.showUserLocation && position != null) _buildUserMarker(center),
    ];

    return MarkerLayer(markers: markers);
  }

  List<Polygon> _buildStructurePolygons() {
    final nearest = _locationService.nearestStructure.value;
    if (nearest == null) return [];

    final geometry = nearest['geometry'];
    if (geometry == null || geometry['type'] != 'Polygon') return [];

    final polygons = <Polygon>[];
    for (var ring in geometry['coordinates']) {
      final points = _parseCoordinates(ring);
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

    return polygons;
  }

  List<Polygon> _buildRoomPolygons() {
    final rooms = _locationService.roomsOnFloor;
    final activeRoute = _locationService.activeRoute.value;
    final polygons = <Polygon>[];

    if (rooms.isEmpty) {
      return polygons;
    }

    final currentFloor = _getCurrentFloor();
    


    for (final room in rooms) {
      final roomFloor = room['floor'];
      
      if (currentFloor != null && roomFloor != currentFloor) {
        continue;
      }

      final geometry = room['geometry'];
      if (geometry == null || geometry['type'] != 'Polygon') continue;

      final coordinates = geometry['coordinates'];
      if (coordinates == null || coordinates is! List || coordinates.isEmpty) continue;

      final isDestination = room['id'] == activeRoute?.destination;

      for (var ring in coordinates) {
        if (ring == null || ring is! List || ring.isEmpty) continue;
        
        final points = _parseCoordinates(ring);
        if (points.length < 3) continue;
        
        polygons.add(
          Polygon(
            points: points,
            color: isDestination
                ? const Color(0xFF3C3CC0).withOpacity(0.6)
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

    return polygons;
  }

  List<Marker> _buildRoomMarkers() {
    final rooms = _locationService.roomsOnFloor;
    final activeRoute = _locationService.activeRoute.value;
    final markers = <Marker>[];

    if (rooms.isEmpty) return markers;

    final currentFloor = _getCurrentFloor();


    for (final room in rooms) {
      final roomFloor = room['floor'];
      
      if (currentFloor != null && roomFloor != currentFloor) {
        continue;
      }

      final centroid = room['centroid'];
      if (centroid == null || centroid['type'] != 'Point') continue;

      final coordinates = centroid['coordinates'];
      if (coordinates == null || coordinates is! List || coordinates.length < 2) continue;

      try {
        final point = LatLng(coordinates[1], coordinates[0]);
        final isDestination = room['id'] == activeRoute?.destination;
        final roomName = room['name'] ?? '';

        if (isDestination) {
          markers.add(_buildDestinationMarker(point));
        }

        if (roomName.isNotEmpty) {
          markers.add(_buildRoomNameMarker(point, roomName, isDestination));
        }
      } catch (e) {
        continue;
      }
    }

    return markers;
  }

  Marker _buildDestinationMarker(LatLng point) {
    return Marker(
      point: point,
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
        child: const Icon(Icons.flag, color: Colors.white, size: 28),
      ),
    );
  }

  Marker _buildRoomNameMarker(LatLng point, String name, bool isDestination) {
    return Marker(
      point: point,
      width: 80,
      height: 16,
      child: Text(
        name,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: isDestination ? const Color(0xFF3C3CC0) : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 🔥 CORREÇÃO: Busca escadas de TODOS os andares, não apenas atual
  List<Marker> _buildStairsMarkers() {
    final activeRoute = _locationService.activeRoute.value;
    if (activeRoute == null) return [];

    final currentFloor = _getCurrentFloor();
    if (currentFloor == null) return [];

    final markers = <Marker>[];
    final addedStairs = <String>{};


  // Busca em todos os segmentos de transição
    for (final segment in activeRoute.segments) {
      if (segment.type == RouteSegmentType.transition) {
        if (segment.path.isEmpty) continue;

        // Extrai os andares da descrição
        final description = segment.description ?? '';
        final regex = RegExp(r'Andar (\d+) → (\d+)');
        final match = regex.firstMatch(description);
        
        if (match != null) {
          final fromFloor = int.tryParse(match.group(1) ?? '');
          final toFloor = int.tryParse(match.group(2) ?? '');
          
          if (fromFloor == currentFloor || toFloor == currentFloor) {
            // Usa o primeiro ponto se o andar atual for origem
            // Usa o último ponto se o andar atual for destino
            final stairPoint = fromFloor == currentFloor 
                ? segment.path.first 
                : segment.path.last;
            
            final stairKey = '${stairPoint.latitude.toStringAsFixed(6)},${stairPoint.longitude.toStringAsFixed(6)}';
            
            if (addedStairs.contains(stairKey)) {
              continue;
            }

            
            markers.add(
              Marker(
                point: stairPoint,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.stairs,
                        color: Colors.white,
                        size: 28,
                      ),
                      Text(
                        '$fromFloor→$toFloor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            
            addedStairs.add(stairKey);
          }
        }
      }
    }

  // Fallback: Se não encontrou nenhuma escada, busca nos segmentos internos
    if (markers.isEmpty) {
      
      for (final segment in activeRoute.segments) {
        if (segment.type == RouteSegmentType.internal && 
            segment.floor == currentFloor &&
            segment.description != null &&
            segment.description!.toLowerCase().contains('escada')) {
          
          if (segment.path.length >= 2) {
            final stairPoint = segment.path.last;
            final stairKey = '${stairPoint.latitude.toStringAsFixed(6)},${stairPoint.longitude.toStringAsFixed(6)}';
            
            if (!addedStairs.contains(stairKey)) {
              
              markers.add(
                Marker(
                  point: stairPoint,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withOpacity(0.6),
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
              
              addedStairs.add(stairKey);
            }
          }
        }
      }
    }

    return markers;
  }

  Marker _buildUserMarker(LatLng center) {
    return Marker(
      point: center,
      width: 80,
      height: 80,
      child: const AnimatedUserMarker(),
    );
  }

  Widget _buildAttribution() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Map tiles by Stamen, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
        style: TextStyle(fontSize: 12, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  LatLng _getCenterPosition(Position? position) {
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return LatLng(-16.294387, -48.944379);
  }

  void _centerMapOnce(LatLng center) {
    if (_locationService.currentPosition.value != null && !_hasCenteredOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(center, widget.zoom);
          _hasCenteredOnce = true;
        } catch (e) {
        }
      });
    }
  }

  
  List<LatLng> _getRoutePointsForCurrentFloor() {
    final activeRoute = _locationService.activeRoute.value;
    if (activeRoute == null) {
      return [];
    }

    final currentFloor = _getCurrentFloor();


    final filteredPoints = <LatLng>[];

    for (final segment in activeRoute.segments) {
      if (segment.type == RouteSegmentType.external) {
        filteredPoints.addAll(segment.path);
      }
    }

    
    if (currentFloor == null) {
      return filteredPoints;
    }

    
    for (final segment in activeRoute.segments) {
      if (segment.type == RouteSegmentType.internal && segment.floor == currentFloor) {
        filteredPoints.addAll(segment.path);
      }
    }

    for (final segment in activeRoute.segments) {
      if (segment.type == RouteSegmentType.transition && segment.path.isNotEmpty) {
        final description = segment.description ?? '';
        final regex = RegExp(r'Andar (\d+) → (\d+)');
        final match = regex.firstMatch(description);
        
        if (match != null) {
          final fromFloor = int.tryParse(match.group(1) ?? '');
          
          if (fromFloor == currentFloor) {
            filteredPoints.add(segment.path.first);
          }
        }
      }
    }

  return filteredPoints;
  }

  int? _getCurrentFloor() {
    final activeRoute = _locationService.activeRoute.value;
    
    if (activeRoute != null) {
      final floorsTraversed = activeRoute.floorsTraversed;
      if (floorsTraversed.isNotEmpty) {
        return floorsTraversed.first;
      }

      final internalSegments = activeRoute.segments
          .where((seg) => seg.floor != null)
          .toList();
      
      if (internalSegments.isNotEmpty) {
        return internalSegments.first.floor;
      }
    }

    final rooms = _locationService.roomsOnFloor;
    if (rooms.isNotEmpty) {
      final firstRoomFloor = rooms.first['floor'] as int?;
      if (firstRoomFloor != null) {
        return firstRoomFloor;
      }
    }

    
    return null;
  }

  List<LatLng> _parseCoordinates(List coordinates) {
    return coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}