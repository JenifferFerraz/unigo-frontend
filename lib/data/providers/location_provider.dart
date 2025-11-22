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

  // ============ UNIFIED ROUTES API ============

  /// Busca rota completa OU apenas estrutura (dependendo se 'start' é fornecido)
  /// 
  /// **COM start**: Retorna rota completa (externa + interna)
  /// **SEM start**: Retorna apenas estrutura e salas (para visualização)
  Future<RouteResponse?> getCompleteRoute({
    List<double>? start, // ✨ OPCIONAL agora
    required int destinationRoomId,
    TransportMode mode = TransportMode.walking,
  }) async {
    try {
      print('[Provider] getCompleteRoute chamado');
      print('  destinationRoomId: $destinationRoomId');
      print('  start: $start');
      print('  mode: $mode');

      // Monta body da requisição
      final requestBody = <String, dynamic>{
        'destinationRoomId': destinationRoomId,
      };

      // ✅ Só adiciona 'start' e 'mode' se houver localização
      if (start != null && start.length == 2) {
        requestBody['start'] = [start[0], start[1]];
        requestBody['mode'] = mode == TransportMode.driving ? 'driving' : 'walking';
        print('[Provider] → Calculando ROTA COMPLETA');
      } else {
        print('[Provider] → Buscando APENAS ESTRUTURA');
      }

      final response = await post('/routes/complete', requestBody);

      print('[Provider] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;
        
        // Verifica se é modo "structure_only" (sem rota)
        final isStructureOnly = data['mode'] == 'structure_only';

        if (isStructureOnly) {
          print('[Provider] ✓ Estrutura recebida (sem rota)');
          
          // Retorna RouteResponse sem rota, apenas com estrutura
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

        // Rota completa (modo normal)
        print('[Provider] ✓ Rota completa recebida');
        final routeResponse = RouteResponse.fromJson(data);
        
        if (routeResponse.success && routeResponse.route != null) {
          print('  - Segmentos: ${routeResponse.route!.segments.length}');
          print('  - Distância: ${routeResponse.route!.totalDistance.toStringAsFixed(0)}m');
          return routeResponse;
        }
      }

      print('[Provider] ❌ Resposta inválida');
      return null;
    } catch (e, stack) {
      print('[Provider] ❌ Erro: $e');
      print(stack);
      return null;
    }
  }

  /// Helper para parse de roomsByFloor
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
      print('[Provider] Erro ao parse roomsByFloor: $e');
      return null;
    }
  }

  /// Busca apenas rota interna (legacy - mantido para compatibilidade)
  /// Endpoint: POST /api/routes/internal
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

  // ============ STRUCTURES ============

  /// Busca todas as estruturas
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

  /// Busca estruturas por query
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

  /// Busca estrutura por ID
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

  // ============ ROOMS ============

  /// Busca salas de uma estrutura em um andar específico
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

  // ============ EXTERNAL ROUTES ============

  /// Lista todas as rotas externas
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

  // ============ HEALTH CHECK ============

  /// Verifica saúde da API
  Future<bool> healthCheck() async {
    try {
      final response = await get('/routes/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ LEGACY METHODS (Compatibilidade) ============

  /// Método legado - usar getCompleteRoute() para novas implementações
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

  /// Método legado para buscar localizações
  @Deprecated('Use searchStructures()')
  Future<List<dynamic>> searchLocations(String query) async {
    final structures = await searchStructures(query);
    return structures.map((s) => s.toJson()).toList();
  }

  /// Método legado para próximas aulas
  @Deprecated('Funcionalidade movida para outro serviço')
  Future<List<dynamic>> getUpcomingClasses() async {
    return [];
  }
}