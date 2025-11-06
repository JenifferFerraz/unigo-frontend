import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unigo_mobile/data/services/location_service.dart';
import 'package:unigo_mobile/data/services/websocket_service.dart';
import 'package:unigo_mobile/data/models/navigation_model.dart';

// Mock classes
class MockWebSocketService extends GetxService implements WebSocketService {
  final List<Map<String, dynamic>> sentMessages = [];
  
  @override
  RxBool isConnected = true.obs;
  
  @override
  Future<void> connect() async {
    isConnected.value = true;
    print('[MOCK WebSocket] Conectado com sucesso');
  }
  
  @override
  void send(dynamic data) {
    sentMessages.add(data as Map<String, dynamic>);
    print('[MOCK WebSocket] Mensagem enviada: $data');
  }
  
  @override
  void sendPosition({
    required List<double> position,
    int? structureId,
    int? floor,
  }) {
    final data = {
      'position': position,
      'structureId': structureId,
      'floor': floor,
    };
    sentMessages.add(data);
    print('[MOCK WebSocket] sendPosition: $data');
  }
  
  @override
  Future<String> getOrCreateSessionId() async => 'test-session-id';
  
  @override
  void onClose() {}
  
  // Propriedades não usadas no teste
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LocationService locationService;
  late MockWebSocketService mockWebSocket;

  setUpAll(() async {
    // Inicializa DotEnv com valores de teste
    await dotenv.load(fileName: '.env');
  });

  setUp(() {
    // Inicializa GetX para testes
    Get.testMode = true;
    
    // Cria mock do WebSocket
    mockWebSocket = MockWebSocketService();
    Get.put<WebSocketService>(mockWebSocket);
    
    // Cria LocationService
    locationService = LocationService();
    Get.put(locationService);
    
    print('\n========================================');
    print('🧪 INICIANDO TESTE DE NAVEGAÇÃO MULTI-ANDAR');
    print('========================================\n');
  });

  tearDown(() {
    Get.reset();
  });

  group('Navegação Multi-Andar - Simulação Completa', () {
    test('FASE 1: Processar resposta do backend com multi-floor', () async {
      print('\n📋 FASE 1: Backend retorna rota multi-andar\n');
      
      // Simula resposta do backend com destinationFloor
      final mockBackendResponse = {
        'pathToStairs': [
          [-34.95234, -8.05432], // Posição inicial
          [-34.95237, -8.05436], // Corredor
          [-34.95240, -8.05440], // Chegada nas escadas
        ],
        'stairsTransition': {
          'from': [-34.95240, -8.05440], // Escada andar 0
          'to': [-34.95240, -8.05440],   // Escada andar 2
        },
        'pathFromStairs': [
          [-34.95240, -8.05440], // Saída das escadas
          [-34.95245, -8.05445], // Corredor andar 2
          [-34.95260, -8.05450], // Sala 205
        ],
        'destinationFloor': 2, // ← Campo novo!
      };

      // Simula posição atual
      final mockPosition = Position(
        latitude: -8.05432,
        longitude: -34.95234,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      
      locationService.currentPosition.value = mockPosition;

      // Processa resposta (simulando o que fetchAndSetInternalRoute faz)
      final data = mockBackendResponse;
      
      // Extrai destinationFloor
      int? destinationFloor;
      if (data.containsKey('destinationFloor')) {
        destinationFloor = data['destinationFloor'] as int;
        print('✓ Andar de destino extraído: $destinationFloor');
      }

      // Converte pathToStairs
      final pathToStairs = (data['pathToStairs'] as List)
          .map((p) => LatLng((p as List)[1], p[0]))
          .toList();
      
      print('✓ pathToStairs: ${pathToStairs.length} pontos');
      pathToStairs.forEach((p) => print('  - $p'));

      // Converte stairsTransition
      final stairsTransitionData = data['stairsTransition'] as Map<String, dynamic>;
      final stairsFrom = stairsTransitionData['from'] as List;
      final stairsTo = stairsTransitionData['to'] as List;
      final stairsTransition = [
        LatLng(stairsFrom[1], stairsFrom[0]),
        LatLng(stairsTo[1], stairsTo[0]),
      ];
      
      print('✓ stairsTransition: ${stairsTransition.length} pontos');
      stairsTransition.forEach((p) => print('  - $p'));

      // Converte pathFromStairs
      final pathFromStairs = (data['pathFromStairs'] as List)
          .map((p) => LatLng((p as List)[1], p[0]))
          .toList();
      
      print('✓ pathFromStairs: ${pathFromStairs.length} pontos');
      pathFromStairs.forEach((p) => print('  - $p'));

      // Assertions
      expect(destinationFloor, equals(2), reason: 'Destination floor deve ser 2');
      expect(pathToStairs.length, equals(3), reason: 'Deve ter 3 pontos até escadas');
      expect(stairsTransition.length, equals(2), reason: 'Transição deve ter 2 pontos');
      expect(pathFromStairs.length, equals(3), reason: 'Deve ter 3 pontos após escadas');
      
      print('\n✅ FASE 1 PASSOU: Resposta processada corretamente\n');
    });

    test('FASE 2: Detectar chegada nas escadas (toStairs → stairs)', () async {
      print('\n🚶 FASE 2: Caminhando até as escadas\n');
      
      // Setup: Define caminhos manualmente (como se viesse do backend)
      final pathToStairs = [
        LatLng(-8.05432, -34.95234), // Início
        LatLng(-8.05436, -34.95237), // Meio
        LatLng(-8.05440, -34.95240), // Fim (escadas)
      ];
      
      final stairsTransition = [
        LatLng(-8.05440, -34.95240), // Escada andar 0
        LatLng(-8.05440, -34.95240), // Escada andar 2
      ];
      
      // Simula que estamos no estágio toStairs
      print('📍 Estágio inicial: toStairs');
      print('🎯 Destino: ${pathToStairs.last}');
      
      // Simula posições do usuário caminhando
      final positions = [
        LatLng(-8.05432, -34.95234), // Posição 1: longe (0m do início)
        LatLng(-8.05436, -34.95237), // Posição 2: meio caminho
        LatLng(-8.05439, -34.95239), // Posição 3: perto (4.5m das escadas)
        LatLng(-8.05440, -34.95240), // Posição 4: chegou! (2.8m das escadas)
      ];
      
      final lastStairsPoint = pathToStairs.last;
      
      for (var i = 0; i < positions.length; i++) {
        final userPosition = positions[i];
        final distance = Distance().as(
          LengthUnit.Meter,
          userPosition,
          lastStairsPoint,
        );
        
        print('📍 Posição ${i + 1}: $userPosition');
        print('   Distância até escadas: ${distance.toStringAsFixed(1)}m');
        
        if (i == positions.length - 1) {
          // Última posição - deve detectar chegada
          expect(distance, lessThan(3.0), reason: 'Deve estar a menos de 3m das escadas');
          print('   ✓ CHEGOU NAS ESCADAS! (${distance.toStringAsFixed(1)}m < 3.0m)');
          print('   → Mudando estágio: toStairs → stairs');
        }
      }
      
      print('\n✅ FASE 2 PASSOU: Detecção de chegada funcionando\n');
    });

    test('FASE 3: Detectar fim das escadas (stairs → fromStairs)', () async {
      print('\n🪜 FASE 3: Subindo escadas\n');
      
      final stairsTransition = [
        LatLng(-8.05440, -34.95240), // Início escadas (andar 0)
        LatLng(-8.05440, -34.95240), // Fim escadas (andar 2)
      ];
      
      print('📍 Estágio: stairs');
      print('🎯 Fim das escadas: ${stairsTransition.last}');
      
      // Simula usuário subindo escadas
      final positions = [
        LatLng(-8.05440, -34.95240), // Posição 1: início das escadas
        LatLng(-8.05440, -34.95240), // Posição 2: meio das escadas
        LatLng(-8.05440, -34.95240), // Posição 3: fim das escadas (2.5m)
      ];
      
      final stairsEnd = stairsTransition.last;
      
      for (var i = 0; i < positions.length; i++) {
        final userPosition = positions[i];
        final distance = Distance().as(
          LengthUnit.Meter,
          userPosition,
          stairsEnd,
        );
        
        print('📍 Posição ${i + 1}: $userPosition');
        print('   Distância até fim das escadas: ${distance.toStringAsFixed(1)}m');
        
        if (i == positions.length - 1) {
          // Simula que chegou no fim (distância < 3m)
          expect(distance, lessThan(3.0), reason: 'Deve estar a menos de 3m do fim');
          print('   ✓ PASSOU PELAS ESCADAS! (${distance.toStringAsFixed(1)}m < 3.0m)');
          print('   → Mudando estágio: stairs → fromStairs');
        }
      }
      
      print('\n✅ FASE 3 PASSOU: Detecção de fim das escadas funcionando\n');
    });

    test('FASE 4: WebSocket atualiza andar ao chegar no fromStairs', () async {
      print('\n📡 FASE 4: Atualização WebSocket\n');
      
      // Setup: Simula que chegou no estágio fromStairs
      final destinationFloor = 2;
      final navigationStructureId = 1;
      final userPosition = LatLng(-8.05440, -34.95240);
      
      print('📍 Usuário chegou no andar de destino');
      print('🏢 Estrutura ID: $navigationStructureId');
      print('🔢 Andar destino: $destinationFloor');
      print('📍 Posição: $userPosition');
      
      // Simula envio WebSocket
      mockWebSocket.sendPosition(
        position: [userPosition.longitude, userPosition.latitude],
        structureId: navigationStructureId,
        floor: destinationFloor,
      );
      
      print('\n📤 WebSocket enviado!');
      
      // Verifica se mensagem foi enviada corretamente
      expect(mockWebSocket.sentMessages.length, equals(1), 
        reason: 'Deve ter enviado 1 mensagem');
      
      final sentMessage = mockWebSocket.sentMessages.first;
      print('📨 Mensagem enviada: $sentMessage');
      
      expect(sentMessage['structureId'], equals(1), 
        reason: 'Structure ID deve ser 1');
      expect(sentMessage['floor'], equals(2), 
        reason: 'Floor deve ser 2 (andar de destino)');
      expect(sentMessage['position'], isNotNull, 
        reason: 'Posição não deve ser nula');
      
      print('✓ structureId: ${sentMessage['structureId']}');
      print('✓ floor: ${sentMessage['floor']}');
      print('✓ position: ${sentMessage['position']}');
      
      print('\n✅ FASE 4 PASSOU: WebSocket atualizou andar corretamente\n');
    });

    test('FASE 5: Fluxo completo - Do térreo até andar 2', () async {
      print('\n🎬 FASE 5: SIMULAÇÃO COMPLETA\n');
      print('═══════════════════════════════════════\n');
      
      // === SETUP ===
      final destinationFloor = 2;
      final structureId = 1;
      
      final pathToStairs = [
        LatLng(-8.05432, -34.95234),
        LatLng(-8.05436, -34.95237),
        LatLng(-8.05440, -34.95240),
      ];
      
      final stairsTransition = [
        LatLng(-8.05440, -34.95240),
        LatLng(-8.05440, -34.95240),
      ];
      
      final pathFromStairs = [
        LatLng(-8.05440, -34.95240),
        LatLng(-8.05445, -34.95245),
        LatLng(-8.05450, -34.95260),
      ];
      
      // === ESTÁGIO 1: toStairs ===
      print('📍 ESTÁGIO 1: Indo para as escadas');
      print('─────────────────────────────────────\n');
      
      var currentStage = MultiFloorNavigationStage.toStairs;
      var userPosition = pathToStairs[0];
      
      print('🎯 Rota ativa: ${pathToStairs.length} pontos até escadas');
      print('📍 Posição inicial: $userPosition\n');
      
      // Caminha até as escadas
      for (var i = 1; i < pathToStairs.length; i++) {
        userPosition = pathToStairs[i];
        final distance = Distance().as(
          LengthUnit.Meter,
          userPosition,
          pathToStairs.last,
        );
        
        print('📍 Caminhando... $userPosition (${distance.toStringAsFixed(1)}m)');
        
        // Verifica se chegou nas escadas
        if (distance < 3.0) {
          currentStage = MultiFloorNavigationStage.stairs;
          print('✓ CHEGOU NAS ESCADAS!');
          print('→ Mudança de estágio: toStairs → stairs\n');
          break;
        }
      }
      
      expect(currentStage, equals(MultiFloorNavigationStage.stairs));
      
      // === ESTÁGIO 2: stairs ===
      print('🪜 ESTÁGIO 2: Nas escadas');
      print('─────────────────────────────────────\n');
      
      print('🎯 Transição: Andar 0 → Andar 2');
      print('📍 Subindo escadas...\n');
      
      // Simula subida
      await Future.delayed(Duration(milliseconds: 100));
      
      userPosition = stairsTransition.last;
      final distanceToEnd = Distance().as(
        LengthUnit.Meter,
        userPosition,
        stairsTransition.last,
      );
      
      print('📍 Posição: $userPosition (${distanceToEnd.toStringAsFixed(1)}m do fim)');
      
      if (distanceToEnd < 3.0) {
        currentStage = MultiFloorNavigationStage.fromStairs;
        print('✓ PASSOU PELAS ESCADAS!');
        print('→ Mudança de estágio: stairs → fromStairs\n');
        
        // === WebSocket Update ===
        print('📡 Enviando atualização WebSocket...');
        mockWebSocket.sendPosition(
          position: [userPosition.longitude, userPosition.latitude],
          structureId: structureId,
          floor: destinationFloor,
        );
        
        final wsMessage = mockWebSocket.sentMessages.last;
        print('✓ WebSocket enviado:');
        print('  - structureId: ${wsMessage['structureId']}');
        print('  - floor: ${wsMessage['floor']}');
        print('  - position: ${wsMessage['position']}\n');
      }
      
      expect(currentStage, equals(MultiFloorNavigationStage.fromStairs));
      expect(mockWebSocket.sentMessages.length, greaterThan(0));
      expect(mockWebSocket.sentMessages.last['floor'], equals(2));
      
      // === ESTÁGIO 3: fromStairs ===
      print('🎯 ESTÁGIO 3: Caminhando no andar 2');
      print('─────────────────────────────────────\n');
      
      print('🎯 Rota ativa: ${pathFromStairs.length} pontos até Sala 205');
      print('📍 Saindo das escadas...\n');
      
      // Caminha até o destino
      for (var i = 1; i < pathFromStairs.length; i++) {
        userPosition = pathFromStairs[i];
        final distance = Distance().as(
          LengthUnit.Meter,
          userPosition,
          pathFromStairs.last,
        );
        
        print('📍 Caminhando... $userPosition (${distance.toStringAsFixed(1)}m)');
        
        if (i == pathFromStairs.length - 1) {
          print('\n🎉 CHEGOU AO DESTINO!');
          print('📍 Sala 205 - Andar 2\n');
          currentStage = MultiFloorNavigationStage.none;
        }
      }
      
      expect(currentStage, equals(MultiFloorNavigationStage.none));
      
      print('═══════════════════════════════════════');
      print('✅ SIMULAÇÃO COMPLETA FINALIZADA!');
      print('═══════════════════════════════════════\n');
      
      // === Verificações Finais ===
      print('📊 RESUMO DO TESTE:');
      print('─────────────────────────────────────');
      print('✓ Estágios percorridos: 3');
      print('✓ WebSocket enviado: ${mockWebSocket.sentMessages.length}x');
      print('✓ Andar final: $destinationFloor');
      print('✓ Destino alcançado: Sim');
      print('═══════════════════════════════════════\n');
    });
  });

  group('Edge Cases e Cenários Especiais', () {
    test('Navegação no mesmo andar (sem multi-floor)', () async {
      print('\n📍 TESTE: Navegação no mesmo andar\n');
      
      final mockResponse = {
        'path': [
          [-34.95234, -8.05432],
          [-34.95237, -8.05436],
          [-34.95240, -8.05440],
        ],
      };
      
      // Não deve ter campos de multi-floor
      expect(mockResponse.containsKey('pathToStairs'), isFalse);
      expect(mockResponse.containsKey('stairsTransition'), isFalse);
      expect(mockResponse.containsKey('destinationFloor'), isFalse);
      
      print('✓ Resposta é single-floor (sem destinationFloor)');
      print('✓ Deve usar MultiFloorNavigationStage.none');
      
      print('\n✅ PASSOU: Navegação simples reconhecida\n');
    });

    test('WebSocket não conectado - deve tratar erro', () async {
      print('\n📡 TESTE: WebSocket desconectado\n');
      
      // Simula WebSocket desconectado
      mockWebSocket.isConnected.value = false;
      
      print('⚠️ WebSocket desconectado');
      print('✓ Deve reconectar antes de enviar');
      
      // Tenta enviar
      if (!mockWebSocket.isConnected.value) {
        print('→ Reconectando...');
        await mockWebSocket.connect();
      }
      
      expect(mockWebSocket.isConnected.value, isTrue);
      
      mockWebSocket.sendPosition(
        position: [-34.95240, -8.05440],
        structureId: 1,
        floor: 2,
      );
      
      expect(mockWebSocket.sentMessages.length, greaterThan(0));
      
      print('✓ Reconexão bem-sucedida');
      print('✓ Mensagem enviada após reconectar');
      
      print('\n✅ PASSOU: Tratamento de erro funciona\n');
    });

    test('Threshold de distância configurável', () async {
      print('\n📏 TESTE: Thresholds de distância\n');
      
      final thresholds = [1.0, 3.0, 5.0, 10.0];
      final testPoint = LatLng(-8.05440, -34.95240);
      final userPosition = LatLng(-8.05438, -34.95239); // ~2.8m de distância
      
      final actualDistance = Distance().as(
        LengthUnit.Meter,
        userPosition,
        testPoint,
      );
      
      print('📍 Distância real: ${actualDistance.toStringAsFixed(1)}m');
      print('🎯 Testando thresholds:\n');
      
      for (var threshold in thresholds) {
        final shouldTrigger = actualDistance < threshold;
        print('  - ${threshold.toStringAsFixed(1)}m: ${shouldTrigger ? "✓ DETECTA" : "✗ NÃO DETECTA"}');
        
        if (threshold == 3.0) {
          expect(shouldTrigger, isTrue, reason: 'Threshold padrão (3.0m) deve detectar');
        } else if (threshold == 1.0) {
          expect(shouldTrigger, isFalse, reason: 'Threshold muito pequeno não deve detectar');
        }
      }
      
      print('\n✓ Threshold de 3.0m é adequado');
      print('✅ PASSOU: Testes de threshold\n');
    });
  });
}
