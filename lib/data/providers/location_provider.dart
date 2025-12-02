import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/env_service.dart';
import '../models/structure_model.dart';
import '../models/navigation_model.dart';

class LocationProvider extends GetConnect {
  final String _baseUrl = EnvService.apiBaseUrl;

  LocationProvider() {
    httpClient.baseUrl = _baseUrl;
    httpClient.timeout = const Duration(seconds: 30);
  }

 
  Future<RouteResponse?> getCompleteRoute({
    List<double>? start, 
    required int destinationRoomId,
    TransportMode mode = TransportMode.walking,
  }) async {
    try {
    

      final requestBody = <String, dynamic>{
        'destinationRoomId': destinationRoomId,
      };

      if (start != null && start.length == 2) {
        requestBody['start'] = [start[0], start[1]];
        requestBody['mode'] = mode == TransportMode.driving ? 'driving' : 'walking';
      } 

      final response = await post('/routes/complete', requestBody);


      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;
        
        final isStructureOnly = data['mode'] == 'structure_only';

        if (isStructureOnly) {
          
          return RouteResponse(
            success: true,
            route: null, // ← SEM ROTA
            structure: data['data']['structure'],
            roomsByFloor: _parseRoomsByFloor(data['data']['roomsByFloor']),
            metadata: {
              'mode': 'structure_only',
              'message': data['message'],
            },
          );
        }

     
        final routeResponse = RouteResponse.fromJson(data);
        
        if (routeResponse.success && routeResponse.route != null) {
          return routeResponse;
        }
      }

      return null;
    } catch (e, stack) {
   
      return null;
    }
  }

  Map<String, List<Map<String, dynamic>>>? _parseRoomsByFloor(dynamic roomsByFloor) {
    if (roomsByFloor == null) return null;

    try {
      final result = <String, List<Map<String, dynamic>>>{};
      
      if (roomsByFloor is Map) {
        roomsByFloor.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = List<Map<String, dynamic>>.from(
              value.map((item) => Map<String, dynamic>.from(item))
            );
          }
        });
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      return null;
    }
  }


  Future<Map<String, dynamic>?> getInternalRoute({
    required int structureId,
    required int floor,
    required List<double> start,
    int? roomId,
  }) async {
    try {
      final body = {
        'structureId': structureId,
        'floor': floor,
        'start': start,
        if (roomId != null) 'roomId': roomId,
      };
      final response = await post('/routes/internal', body);
      if (response.statusCode == 200 && response.body != null) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<List<Structure>> getAllStructures() async {
    try {
      final response = await get('/structures');
      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic> data = response.body;
        return data.map((json) => Structure.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Structure>> searchStructures(String query) async {
    try {
      final response = await get('/room/all?search=$query');
      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic> data = response.body;
        return data.map((json) => Structure.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Structure?> getStructureById(int id) async {
    try {
      final response = await get('/structures/$id');
      if (response.statusCode == 200 && response.body != null) {
        return Structure.fromJson(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<List<Map<String, dynamic>>> getRoomsByFloor({
    required int structureId,
    required int floor,
  }) async {
    try {
      final response = await get(
        '/structures/$structureId/floors/$floor/rooms',
      );
      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic> data = response.body;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExternalRoutes({
    TransportMode? mode,
  }) async {
    try {
      final modeParam = mode != null 
          ? '?mode=${mode == TransportMode.driving ? 'driving' : 'walking'}'
          : '';
      final response = await get('/routes/external$modeParam');
      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic> data = response.body;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  Future<bool> healthCheck() async {
    try {
      final response = await get('/routes/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  @Deprecated('Use getCompleteRoute() para rotas unificadas')
  Future<NavigationRoute?> getNavigationRoute(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final distance = Distance().as(
        LengthUnit.Meter,
        start,
        end,
      );
      return NavigationRoute(
        segments: [
          RouteSegment(
            type: RouteSegmentType.internal,
            mode: TransportMode.walking,
            path: [start, end],
            distance: distance,
            description: 'Caminho direto',
          ),
        ],
        totalDistance: distance,
        estimatedTime: distance / 1.4 / 60,
      );
    } catch (e) {
      return null;
    }
  }

  @Deprecated('Use searchStructures()')
  Future<List<dynamic>> searchLocations(String query) async {
    final structures = await searchStructures(query);
    return structures.map((s) => s.toJson()).toList();
  }

  @Deprecated('Funcionalidade movida para outro serviço')
  Future<List<dynamic>> getUpcomingClasses() async {
    return [];
  }
}