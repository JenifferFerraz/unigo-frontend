// route_debug_page.dart
// Coloque em: lib/features/debug/presentation/route_debug_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/env_service.dart';

class RouteDebugPage extends StatefulWidget {
  const RouteDebugPage({Key? key}) : super(key: key);

  @override
  State<RouteDebugPage> createState() => _RouteDebugPageState();
}

class _RouteDebugPageState extends State<RouteDebugPage> {
  // Usa o EnvService para pegar a URL correta automaticamente
  String get _baseUrl => EnvService.apiBaseUrl;

  final MapController _mapController = MapController();
  
  // Dados
  List<dynamic> _internalRoutes = [];
  List<dynamic> _externalRoutes = [];
  List<dynamic> _rooms = [];
  List<dynamic> _structures = [];
  
  bool _loading = true;
  String? _error;
  
  // Filtros - Rotas
  bool _showInternal = true;
  bool _showExternal = true;
  bool _showDoors = true;
  bool _showStairs = true;
  bool _showMainEntrance = true;
  
  // Filtros - Rooms
  bool _showRooms = true;
  bool _showRoomNames = true;
  bool _showStructures = true;
  
  int? _selectedFloor;
  
  Map<String, int> _stats = {};
  List<int> _availableFloors = [];
  
  // Seleção
  Map<String, dynamic>? _selectedItem;
  String? _selectedType; // 'route', 'room', 'structure'

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Carregar rotas
      final routesResponse = await http.get(Uri.parse('$_baseUrl/routes/all'));
      
      // Carregar rooms
      final roomsResponse = await http.get(Uri.parse('$_baseUrl/room/all'));
      
      // Carregar structures
      final structuresResponse = await http.get(Uri.parse('$_baseUrl/structure/all'));

      if (routesResponse.statusCode == 200) {
        final routesData = json.decode(routesResponse.body);
        _internalRoutes = routesData['data']?['internal'] ?? [];
        _externalRoutes = routesData['data']?['external'] ?? [];
      }

      if (roomsResponse.statusCode == 200) {
        final roomsData = json.decode(roomsResponse.body);
        // Ajuste conforme a estrutura da sua API
        _rooms = roomsData is List ? roomsData : (roomsData['data'] ?? []);
      }

      if (structuresResponse.statusCode == 200) {
        final structuresData = json.decode(structuresResponse.body);
        _structures = structuresData is List ? structuresData : (structuresData['data'] ?? []);
      }

      setState(() {
        _loading = false;
        _calculateStats();
        _extractFloors();
      });
      
      _showSnackBar('✅ Dados carregados: ${_internalRoutes.length + _externalRoutes.length} rotas, ${_rooms.length} rooms');
      
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
        _loading = false;
      });
    }
  }

  void _calculateStats() {
    int doors = 0, stairs = 0, mainEntrance = 0;

    for (var route in _internalRoutes) {
      final props = route['properties'] ?? {};
      if (props['isDoor'] == true) doors++;
      if (props['isStairs'] == true) stairs++;
      if (props['In/Out'] == true) mainEntrance++;
    }

    _stats = {
      'internalRoutes': _internalRoutes.length,
      'externalRoutes': _externalRoutes.length,
      'rooms': _rooms.length,
      'structures': _structures.length,
      'doors': doors,
      'stairs': stairs,
      'mainEntrance': mainEntrance,
    };
  }

  void _extractFloors() {
    final floors = <int>{};
    
    // Andares das rotas
    for (var route in _internalRoutes) {
      final floor = route['floor'];
      if (floor != null) floors.add(floor);
    }
    
    // Andares dos rooms
    for (var room in _rooms) {
      final floor = room['floor'];
      if (floor != null) floors.add(floor);
    }
    
    _availableFloors = floors.toList()..sort();
  }
  
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Debug Completo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showStatsDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMap(),
              Positioned(right: 8, bottom: 100, child: _buildFloorSelector()),
              Positioned(left: 8, bottom: 100, child: _buildLayerSelector()),
            ],
          ),
        ),
        _buildLegend(),
        if (_selectedItem != null) _buildDetailsPanel(),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('Rotas Int', _showInternal, (v) => setState(() => _showInternal = v), Colors.blueGrey),
            _chip('Rotas Ext', _showExternal, (v) => setState(() => _showExternal = v), Colors.green),
            _chip('Rooms', _showRooms, (v) => setState(() => _showRooms = v), Colors.indigo),
            _chip('Nomes', _showRoomNames, (v) => setState(() => _showRoomNames = v), Colors.cyan),
            _chip('Estruturas', _showStructures, (v) => setState(() => _showStructures = v), Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool value, Function(bool) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: value,
        onSelected: onChanged,
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
      ),
    );
  }

  Widget _buildFloorSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Andar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 4),
            ..._availableFloors.reversed.map((f) => _floorButton(f)),
            _floorButton(null, label: '∞'),
          ],
        ),
      ),
    );
  }

  Widget _floorButton(int? floor, {String? label}) {
    final isSelected = _selectedFloor == floor;
    return GestureDetector(
      onTap: () => setState(() => _selectedFloor = floor),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label ?? '$floor',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLayerSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _layerToggle(Icons.route, 'Portas', _showDoors, (v) => setState(() => _showDoors = v)),
            _layerToggle(Icons.stairs, 'Escadas', _showStairs, (v) => setState(() => _showStairs = v)),
            _layerToggle(Icons.door_front_door, 'Entrada', _showMainEntrance, (v) => setState(() => _showMainEntrance = v)),
          ],
        ),
      ),
    );
  }

  Widget _layerToggle(IconData icon, String tooltip, bool value, Function(bool) onChanged) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: value ? Colors.deepPurple.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: value ? Border.all(color: Colors.deepPurple) : null,
          ),
          child: Icon(icon, size: 18, color: value ? Colors.deepPurple : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(-16.294387, -48.944379),
        initialZoom: 18,
        maxZoom: 22,
        onTap: (_, __) => setState(() {
          _selectedItem = null;
          _selectedType = null;
        }),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        // 1. Structures (mais atrás)
        if (_showStructures) PolygonLayer(polygons: _buildStructurePolygons()),
        // 2. Rooms
        if (_showRooms) PolygonLayer(polygons: _buildRoomPolygons()),
        // 3. Rotas (polylines)
        PolylineLayer(polylines: _buildPolylines()),
        // 4. Marcadores (mais à frente)
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  // ==================== POLYGONS ====================

  List<Polygon> _buildStructurePolygons() {
    final polygons = <Polygon>[];

    for (var structure in _structures) {
      final geometry = structure['geometry'];
      if (geometry == null || geometry['type'] != 'Polygon') continue;

      final coords = geometry['coordinates'] as List?;
      if (coords == null || coords.isEmpty) continue;

      for (var ring in coords) {
        final points = _parseCoords(ring);
        if (points.length < 3) continue;

        polygons.add(Polygon(
          points: points,
          color: Colors.brown.withOpacity(0.1),
          borderColor: Colors.brown,
          borderStrokeWidth: 3,
          isFilled: true,
        ));
      }
    }

    return polygons;
  }

  List<Polygon> _buildRoomPolygons() {
    final polygons = <Polygon>[];

    for (var room in _rooms) {
      final floor = room['floor'] as int?;
      if (_selectedFloor != null && floor != _selectedFloor) continue;

      final geometry = room['geometry'];
      if (geometry == null || geometry['type'] != 'Polygon') continue;

      final coords = geometry['coordinates'] as List?;
      if (coords == null || coords.isEmpty) continue;

      final isSelected = _selectedItem == room && _selectedType == 'room';

      for (var ring in coords) {
        final points = _parseCoords(ring);
        if (points.length < 3) continue;

        polygons.add(Polygon(
          points: points,
          color: isSelected 
              ? Colors.indigo.withOpacity(0.5) 
              : Colors.indigo.withOpacity(0.15),
          borderColor: isSelected ? Colors.indigo : Colors.indigo.withOpacity(0.6),
          borderStrokeWidth: isSelected ? 3 : 1.5,
          isFilled: true,
        ));
      }
    }

    return polygons;
  }

  // ==================== POLYLINES ====================

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Externas
    if (_showExternal) {
      for (var route in _externalRoutes) {
        final geometry = route['geometry'];
        if (geometry == null) continue;
        final coords = geometry['coordinates'] as List?;
        if (coords == null) continue;

        final mode = route['properties']?['mode'] ?? 'walking';
        final color = mode == 'driving' ? Colors.blue : Colors.green;

        for (var line in coords) {
          final points = _parseCoords(line);
          if (points.length < 2) continue;
          polylines.add(Polyline(points: points, color: color, strokeWidth: 4));
        }
      }
    }

    // Internas
    if (_showInternal) {
      for (var route in _internalRoutes) {
        final floor = route['floor'] as int?;
        if (_selectedFloor != null && floor != _selectedFloor) continue;

        final props = route['properties'] ?? {};
        final isDoor = props['isDoor'] == true;
        final isStairs = props['isStairs'] == true;
        final isMainEntrance = props['In/Out'] == true;

        if (isDoor && !_showDoors) continue;
        if (isStairs && !_showStairs) continue;
        if (isMainEntrance && !_showMainEntrance) continue;

        final geometry = route['geometry'];
        if (geometry == null) continue;
        final coords = geometry['coordinates'] as List?;
        if (coords == null) continue;

        Color color = Colors.blueGrey;
        double width = 2;

        if (isMainEntrance) {
          color = Colors.red;
          width = 5;
        } else if (isDoor) {
          color = Colors.orange;
          width = 3;
        } else if (isStairs) {
          color = Colors.purple;
          width = 4;
        }

        for (var line in coords) {
          final points = _parseCoords(line);
          if (points.length < 2) continue;
          polylines.add(Polyline(points: points, color: color, strokeWidth: width));
        }
      }
    }

    return polylines;
  }

  // ==================== MARKERS ====================

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Nomes dos rooms
    if (_showRoomNames && _showRooms) {
      for (var room in _rooms) {
        final floor = room['floor'] as int?;
        if (_selectedFloor != null && floor != _selectedFloor) continue;

        final centroid = room['centroid'];
        if (centroid == null) continue;

        final coords = centroid['coordinates'] as List?;
        if (coords == null || coords.length < 2) continue;

        final point = LatLng(coords[1], coords[0]);
        final name = room['name'] ?? 'Sem nome';

        markers.add(Marker(
          point: point,
          width: 100,
          height: 40,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedItem = room;
              _selectedType = 'room';
            }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.indigo.withOpacity(0.5)),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.indigo),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text('F$floor', style: TextStyle(fontSize: 7, color: Colors.grey[600])),
              ],
            ),
          ),
        ));
      }
    }

    // Marcadores de rotas especiais
    if (_showMainEntrance && _showInternal) {
      for (var route in _internalRoutes) {
        final props = route['properties'] ?? {};
        if (props['In/Out'] != true) continue;

        final floor = route['floor'] as int?;
        if (_selectedFloor != null && floor != _selectedFloor) continue;

        final point = _getFirstPoint(route);
        if (point == null) continue;

        markers.add(_routeMarker(point, Icons.door_front_door, Colors.red, route, 'route'));
      }
    }

    if (_showStairs && _showInternal) {
      for (var route in _internalRoutes) {
        final props = route['properties'] ?? {};
        if (props['isStairs'] != true) continue;

        final floor = route['floor'] as int?;
        if (_selectedFloor != null && floor != _selectedFloor) continue;

        final point = _getFirstPoint(route);
        if (point == null) continue;

        markers.add(_routeMarker(point, Icons.stairs, Colors.purple, route, 'route'));
      }
    }

    return markers;
  }

  Marker _routeMarker(LatLng point, IconData icon, Color color, Map<String, dynamic> data, String type) {
    return Marker(
      point: point,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedItem = data;
          _selectedType = type;
        }),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  LatLng? _getFirstPoint(Map<String, dynamic> route) {
    final geometry = route['geometry'];
    if (geometry == null) return null;
    final coords = geometry['coordinates'] as List?;
    if (coords == null || coords.isEmpty) return null;
    final line = coords[0] as List?;
    if (line == null || line.isEmpty) return null;
    return LatLng(line[0][1], line[0][0]);
  }

  List<LatLng> _parseCoords(List coords) {
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  // ==================== LEGEND ====================

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _legendItem(Colors.indigo, 'Rooms', isPolygon: true),
            _legendItem(Colors.brown, 'Estrutura', isPolygon: true),
            _legendItem(Colors.green, 'A pé'),
            _legendItem(Colors.blue, 'Carro'),
            _legendItem(Colors.red, 'Entrada'),
            _legendItem(Colors.purple, 'Escada'),
            _legendItem(Colors.orange, 'Porta'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {bool isPolygon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            width: isPolygon ? 14 : 16,
            height: isPolygon ? 14 : 4,
            decoration: BoxDecoration(
              color: isPolygon ? color.withOpacity(0.3) : color,
              border: isPolygon ? Border.all(color: color, width: 2) : null,
              borderRadius: isPolygon ? BorderRadius.circular(2) : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ==================== DETAILS PANEL ====================

  Widget _buildDetailsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.deepPurple.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _selectedType == 'room' ? Icons.meeting_room : Icons.route,
                size: 18,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedType == 'room' ? 'Detalhes da Sala' : 'Detalhes da Rota',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() {
                  _selectedItem = null;
                  _selectedType = null;
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 12),
          if (_selectedType == 'room') ...[
            Text('Nome: ${_selectedItem!['name'] ?? 'Sem nome'}'),
            Text('ID: ${_selectedItem!['id']}'),
            Text('Andar: ${_selectedItem!['floor']}'),
            if (_selectedItem!['type'] != null) Text('Tipo: ${_selectedItem!['type']}'),
          ] else ...[
            Text('ID: ${_selectedItem!['id']}'),
            Text('Andar: ${_selectedItem!['floor']}'),
            if (_selectedItem!['properties'] != null) ...[
              if (_selectedItem!['properties']['isDoor'] == true) const Text('🚪 É uma porta'),
              if (_selectedItem!['properties']['isStairs'] == true) const Text('🪜 É uma escada'),
              if (_selectedItem!['properties']['In/Out'] == true) const Text('🚩 Entrada Principal'),
            ],
          ],
        ],
      ),
    );
  }

  // ==================== STATS DIALOG ====================

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📊 Estatísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ROTAS', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  Internas: ${_stats['internalRoutes']}'),
            Text('  Externas: ${_stats['externalRoutes']}'),
            const Divider(),
            const Text('ELEMENTOS', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  🚪 Portas: ${_stats['doors']}'),
            Text('  🪜 Escadas: ${_stats['stairs']}'),
            Text('  🚩 Entradas: ${_stats['mainEntrance']}'),
            const Divider(),
            const Text('ESPAÇOS', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  🏢 Estruturas: ${_stats['structures']}'),
            Text('  🚪 Rooms: ${_stats['rooms']}'),
            const Divider(),
            Text('Andares: ${_availableFloors.join(", ")}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}