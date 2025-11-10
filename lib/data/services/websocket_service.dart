import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/env_service.dart';
import 'location_service.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final RxBool isConnected = false.obs;
  String? _sessionId;
  
  static const _sessionKey = 'session_id';

  Future<String> _ensureSessionId() async {
    if (_sessionId != null) return _sessionId!;
    
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionKey) ?? const Uuid().v4();
    
    if (!prefs.containsKey(_sessionKey)) {
      await prefs.setString(_sessionKey, _sessionId!);
    }
    
    return _sessionId!;
  }

  Future<void> connect() async {
    if (isConnected.value) return;
    
    try {
      final sessionId = await _ensureSessionId();
      final wsUrl = EnvService.socketUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/ws?room=$sessionId');
      
      _channel = WebSocketChannel.connect(uri);
      isConnected.value = true;
      
      _channel!.stream.listen(
        _handleIncomingMessage,
        onDone: () => isConnected.value = false,
        onError: (_) => isConnected.value = false,
      );
      
      print('[WebSocket] Conectado com sessão: $sessionId');
    } catch (e) {
      print('[WebSocket] Erro ao conectar: $e');
      isConnected.value = false;
    }
  }

  void sendPosition({
    required List<double> position,
    int? structureId,
    int? floor,
  }) {
    if (!isConnected.value) return;
    
    _send({
      'position': position,
      if (structureId != null) 'structureId': structureId,
      if (floor != null) 'floor': floor,
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      print('[WebSocket] Erro ao enviar: $e');
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;

      if (!Get.isRegistered<LocationService>()) return;

      final locationService = Get.find<LocationService>();

      if (locationService.isNavigating.value && type != 'navigationUpdate') {
        return;
      }

      switch (type) {
        case 'roomsOnFloor':
          _handleRoomsUpdate(data, locationService);
          break;
        case 'nearestStructure':
          _handleStructureUpdate(data, locationService);
          break;
        case 'error':
          print('[WebSocket] Erro do servidor: ${data['message']}');
          break;
      }
    } catch (e) {
      print('[WebSocket] Erro ao processar mensagem: $e');
    }
  }

  void _handleRoomsUpdate(Map<String, dynamic> data, LocationService service) {
    final rooms = data['rooms'];
    if (rooms is List) {
      service.roomsOnFloor.assignAll(rooms.cast<Map<String, dynamic>>());
    }
  }

  void _handleStructureUpdate(Map<String, dynamic> data, LocationService service) {
    final structure = data['structure'];
    if (structure != null) {
      service.nearestStructure.value = structure;
    }
  }

  void clearSessionData() {
    if (!Get.isRegistered<LocationService>()) return;
    
    final service = Get.find<LocationService>();
    service.roomsOnFloor.clear();
    service.nearestStructure.value = null;
  }

  Future<void> disconnect() async {
    try {
      clearSessionData();
      if (isConnected.value) {
        await _channel?.sink.close(status.goingAway);
        _channel = null;
        isConnected.value = false;
      }
    } catch (e) {
      print('[WebSocket] Erro ao desconectar: $e');
    }
  }

  Future<void> clearSessionId() async {
    _sessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}