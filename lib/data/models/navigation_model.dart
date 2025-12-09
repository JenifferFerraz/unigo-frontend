import 'package:latlong2/latlong.dart';


/// Tipos de segmento de rota
enum RouteSegmentType {
  external,  // Rota externa (a pé ou carro)
  internal,  // Rota interna (dentro do prédio)
  transition, // Transição entre andares (escadas/elevador)
}

/// Modos de transporte
enum TransportMode {
  walking,
  driving,
}

/// Segmento individual da rota (pode ser externo, interno ou transição)
class RouteSegment {
  final RouteSegmentType type;
  final TransportMode mode;
  final List<LatLng> path;
  final double distance; // metros
  final int? floor; // Andar (apenas para rotas internas/transições)
  final String description;
  final int? fromFloor; // Para transições
  final int? toFloor; // Para transições

  RouteSegment({
    required this.type,
    required this.mode,
    required this.path,
    required this.distance,
    this.floor,
    required this.description,
    this.fromFloor,
    this.toFloor,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      type: _parseSegmentType(json['type']),
      mode: _parseTransportMode(json['mode']),
      path: (json['path'] as List)
          .map((coord) => LatLng(coord[1], coord[0])) // [lng, lat] → LatLng
          .toList(),
      distance: (json['distance'] as num).toDouble(),
      floor: json['floor'],
      description: json['description'] ?? '',
      fromFloor: json['fromFloor'],
      toFloor: json['toFloor'],
    );
  }

  static RouteSegmentType _parseSegmentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'external':
        return RouteSegmentType.external;
      case 'internal':
        return RouteSegmentType.internal;
      case 'transition':
        return RouteSegmentType.transition;
      default:
        return RouteSegmentType.internal;
    }
  }

  static TransportMode _parseTransportMode(String? mode) {
    return mode?.toLowerCase() == 'driving' 
        ? TransportMode.driving 
        : TransportMode.walking;
  }

  /// Verifica se é transição de escadas
  bool get isStairTransition => type == RouteSegmentType.transition;

  /// Verifica se é rota externa
  bool get isExternal => type == RouteSegmentType.external;

  /// Verifica se é rota interna
  bool get isInternal => type == RouteSegmentType.internal;

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'mode': mode == TransportMode.driving ? 'driving' : 'walking',
      'path': path.map((p) => [p.longitude, p.latitude]).toList(),
      'distance': distance,
      'floor': floor,
      'description': description,
      'fromFloor': fromFloor,
      'toFloor': toFloor,
    };
  }
}

/// Rota de navegação completa (suporta rotas unificadas)
class NavigationRoute {
  final List<RouteSegment> segments;
  final double totalDistance; // metros
  final double estimatedTime; // minutos
  final int? destination; // ID da sala/estrutura de destino
  final TransportMode mode;
  final RouteSummary? summary;

  NavigationRoute({
    required this.segments,
    required this.totalDistance,
    required this.estimatedTime,
    this.destination,
    this.mode = TransportMode.walking,
    this.summary,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    print('[NavigationRoute.fromJson] Parsing route data...');
    print('  totalDistance: ${json['totalDistance']}');
    print('  estimatedTime: ${json['estimatedTime']}');
    print('  segments: ${json['segments']?.length ?? 0}');
    
    return NavigationRoute(
      segments: (json['segments'] as List?)
          ?.map((seg) => RouteSegment.fromJson(seg))
          .toList() ?? [],
      totalDistance: (json['totalDistance'] as num).toDouble(),
      estimatedTime: (json['estimatedTime'] as num).toDouble(),
      destination: json['destination'],
      mode: json['mode'] == 'driving' 
          ? TransportMode.driving 
          : TransportMode.walking,
      summary: json['summary'] != null 
          ? RouteSummary.fromJson(json['summary']) 
          : null,
    );
  }

  /// Retorna todos os pontos da rota combinados
  /// Conecta os segmentos corretamente, evitando duplicação de pontos
  List<LatLng> get allPoints {
    if (segments.isEmpty) return [];
    
    final points = <LatLng>[];
    
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final segmentPoints = segment.path;
      
      if (segmentPoints.isEmpty) continue;
      
      // Para o primeiro segmento, adiciona todos os pontos
      if (i == 0) {
        points.addAll(segmentPoints);
      } else {
        // Para segmentos subsequentes, verifica se o primeiro ponto
        // é o mesmo que o último ponto do segmento anterior
        final lastPoint = points.last;
        final firstPoint = segmentPoints.first;
        
        // Se os pontos são diferentes (ou muito próximos), adiciona todos
        // Caso contrário, pula o primeiro ponto para evitar duplicação
        final distance = Distance().as(
          LengthUnit.Meter,
          lastPoint,
          firstPoint,
        );
        
        if (distance > 1.0) {
          // Pontos são diferentes, adiciona todos
          points.addAll(segmentPoints);
        } else {
          // Pontos são muito próximos (provavelmente o mesmo), pula o primeiro
          if (segmentPoints.length > 1) {
            points.addAll(segmentPoints.skip(1));
          }
        }
      }
    }
    
    return points;
  }

  /// Retorna apenas pontos de rotas internas
  List<LatLng> get internalPoints {
    return segments
        .where((seg) => seg.isInternal)
        .expand((seg) => seg.path)
        .toList();
  }

  /// Retorna apenas pontos de rotas externas
  List<LatLng> get externalPoints {
    return segments
        .where((seg) => seg.isExternal)
        .expand((seg) => seg.path)
        .toList();
  }

  /// Retorna segmentos de um andar específico
  List<RouteSegment> segmentsForFloor(int floor) {
    return segments
        .where((seg) => seg.floor == floor)
        .toList();
  }

  /// Retorna todos os andares percorridos
  List<int> get floorsTraversed {
    final floors = segments
        .where((seg) => seg.floor != null)
        .map((seg) => seg.floor!)
        .toSet()
        .toList();
    floors.sort();
    return floors;
  }

  /// Verifica se é rota multi-andar
  bool get isMultiFloor => floorsTraversed.length > 1;

  /// Distância total em km (formatada)
  String get distanceFormatted {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)}m';
    }
    return '${(totalDistance / 1000).toStringAsFixed(2)}km';
  }

  /// Tempo estimado formatado
  String get timeFormatted {
    final minutes = estimatedTime.round();
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'segments': segments.map((s) => s.toJson()).toList(),
      'totalDistance': totalDistance,
      'estimatedTime': estimatedTime,
      'destination': destination,
      'mode': mode == TransportMode.driving ? 'driving' : 'walking',
      'summary': summary?.toJson(),
    };
  }
}

/// Resumo da rota
class RouteSummary {
  final double externalDistance; // metros
  final double internalDistance; // metros
  final List<int> floorsTraversed;

  RouteSummary({
    required this.externalDistance,
    required this.internalDistance,
    required this.floorsTraversed,
  });

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      externalDistance: (json['externalDistance'] as num).toDouble(),
      internalDistance: (json['internalDistance'] as num).toDouble(),
      floorsTraversed: List<int>.from(json['floorsTraversed'] ?? []),
    );
  }

  double get totalDistance => externalDistance + internalDistance;

  Map<String, dynamic> toJson() {
    return {
      'externalDistance': externalDistance,
      'internalDistance': internalDistance,
      'floorsTraversed': floorsTraversed,
    };
  }
}

// ============ LEGACY NAVIGATION STEP (Compatibilidade) ============

/// Step de navegação (modelo legado - mantido para compatibilidade)
class NavigationStep {
  final String instruction;
  final LatLng startPoint;
  final LatLng endPoint;
  final double distance;
  final int duration;
  final String maneuver;
  final double? heading;

  NavigationStep({
    required this.instruction,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.duration,
    required this.maneuver,
    this.heading,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['instruction'],
      startPoint: LatLng(json['startPoint'][0], json['startPoint'][1]),
      endPoint: LatLng(json['endPoint'][0], json['endPoint'][1]),
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'],
      maneuver: json['maneuver'],
      heading: json['heading']?.toDouble(),
    );
  }
}

// ============ NAVIGATION PROGRESS ============

/// Progresso da navegação
class NavigationProgress {
  final int currentSegmentIndex; // Índice do segmento atual
  final double distanceToNextSegment; // metros
  final double distanceToDestination; // metros
  final int estimatedTimeRemaining; // segundos
  final int? currentFloor; // Andar atual (se aplicável)

  NavigationProgress({
    required this.currentSegmentIndex,
    required this.distanceToNextSegment,
    required this.distanceToDestination,
    required this.estimatedTimeRemaining,
    this.currentFloor,
  });

  /// Progresso em porcentagem (0-100)
  double get progressPercentage {
    // Assumindo que distanceToDestination é atualizado conforme progresso
    return 100.0; // Implementar cálculo real se necessário
  }

  /// Tempo restante formatado
  String get timeRemainingFormatted {
    final minutes = estimatedTimeRemaining ~/ 60;
    final seconds = estimatedTimeRemaining % 60;
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Distância restante formatada
  String get distanceRemainingFormatted {
    if (distanceToDestination < 1000) {
      return '${distanceToDestination.toStringAsFixed(0)}m';
    }
    return '${(distanceToDestination / 1000).toStringAsFixed(2)}km';
  }
}

// ============ VOICE GUIDANCE ============

enum VoiceGuidanceLevel {
  off,
  basic,
  detailed,
}

// ============ ROUTE REQUEST (para API) ============

/// Request para calcular rota completa
class RouteRequest {
  final List<double> start; // [longitude, latitude]
  final int destinationRoomId;
  final TransportMode mode;

  RouteRequest({
    required this.start,
    required this.destinationRoomId,
    this.mode = TransportMode.walking,
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'destinationRoomId': destinationRoomId,
      'mode': mode == TransportMode.driving ? 'driving' : 'walking',
    };
  }
}

class RouteResponse {
  final bool success;
  final NavigationRoute? route;
  final String? error;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? structure;
  final Map<String, List<Map<String, dynamic>>>? roomsByFloor; 

  RouteResponse({
    required this.success,
    this.route,
    this.error,
    this.metadata,
    this.structure,
    this.roomsByFloor,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('[RouteResponse] Parsing JSON...');
      print('  success: ${json['success']}');
      print('  mode: ${json['mode']}');
      
      final isStructureOnly = json['mode'] == 'structure_only';
      
      if (isStructureOnly) {
        // ✨ Modo visualização: SEM rota
        print('[RouteResponse] ✓ Modo: structure_only');
        
        final data = json['data'] as Map<String, dynamic>?;
        
        return RouteResponse(
          success: json['success'] ?? true,
          route: null, // SEM ROTA
          structure: data?['structure'] as Map<String, dynamic>?,
          roomsByFloor: _parseRoomsByFloor(data?['roomsByFloor']),
          metadata: {
            'mode': 'structure_only',
            'message': json['message'],
            'floors': data?['floors'],
          },
        );
      }
      
      // ✅ Modo navegação: COM rota
      print('[RouteResponse] ✓ Modo: navegação completa');
      
      final data = json['data'] as Map<String, dynamic>?;
      
      if (data == null) {
        print('[RouteResponse] ⚠️ data é null');
        return RouteResponse(
          success: false,
          error: 'Dados da rota não encontrados',
        );
      }
      
      return RouteResponse(
        success: json['success'] ?? true,
        route: NavigationRoute.fromJson(data),
        structure: data['structure'] as Map<String, dynamic>?,
        roomsByFloor: _parseRoomsByFloor(data['roomsByFloor']),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
      
    } catch (e, stack) {
      print('[RouteResponse] ❌ Erro ao parse: $e');
      print(stack);
      
      return RouteResponse(
        success: false,
        error: 'Erro ao processar resposta: $e',
      );
    }
  }


  static Map<String, List<Map<String, dynamic>>>? _parseRoomsByFloor(
    dynamic roomsByFloor
  ) {
    if (roomsByFloor == null) return null;

    try {
      final result = <String, List<Map<String, dynamic>>>{};
      
      if (roomsByFloor is Map) {
        roomsByFloor.forEach((key, value) {
          if (value is List) {
            result[key.toString()] = List<Map<String, dynamic>>.from(
              value.map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
            );
          }
        });
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      print('[RouteResponse] ⚠️ Erro ao parse roomsByFloor: $e');
      return null;
    }
  }

  bool get isStructureOnly => metadata?['mode'] == 'structure_only';

  /// Verifica se tem rota de navegação
  bool get hasRoute => route != null;

  /// Mensagem do servidor (quando disponível)
  String? get message => metadata?['message'];

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'route': route?.toJson(),
      'error': error,
      'metadata': metadata,
      'structure': structure,
      'roomsByFloor': roomsByFloor,
    };
  }

  @override
  String toString() {
    if (isStructureOnly) {
      final structureName = structure?['name'] ?? 'Desconhecida';
      final floors = metadata?['floors'] as List? ?? [];
      return 'RouteResponse(mode: structure_only, structure: $structureName, floors: $floors)';
    }
    
    if (hasRoute) {
      return 'RouteResponse(route: ${route!.segments.length} segmentos, ${route!.distanceFormatted})';
    }
    
    return 'RouteResponse(success: $success, error: $error)';
  }
}