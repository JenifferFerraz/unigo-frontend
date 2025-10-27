
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/env_service.dart';
import 'location_service.dart';

class WebSocketService extends GetxService {
  late WebSocketChannel channel;
  RxBool isConnected = false.obs;

  Future<String> getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    var sessionId = prefs.getString('session_id');
    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await prefs.setString('session_id', sessionId);
    }
    return sessionId;
  }

  Future<void> connect() async {
    final sessionId = await getOrCreateSessionId();
    final url = '${EnvService.socketUrl.replaceFirst('http', 'ws')}/ws?room=$sessionId';
    channel = WebSocketChannel.connect(Uri.parse(url));
    isConnected.value = true;
    channel.stream.listen((message) {
      _handleMessage(message);
    }, onDone: () {
      isConnected.value = false;
    }, onError: (error) {
      isConnected.value = false;
    });
  }

  void send(dynamic data) {
    if (isConnected.value) {
      channel.sink.add(jsonEncode(data));
    }
  }
  
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
    send(data);
  }

  void _handleMessage(dynamic message) {
    final data = jsonDecode(message);
    
    // Verifica se LocationService está registrado antes de usar
    if (!Get.isRegistered<LocationService>()) {
      return;
    }
    
    final locationService = Get.find<LocationService>();
    if (data['type'] == 'roomsOnFloor') {
      if (data['rooms'] is List) {
        locationService.roomsOnFloor.assignAll(List<Map<String, dynamic>>.from(data['rooms']));
      }
    } else if (data['type'] == 'nearestStructure') {
      locationService.nearestStructure.value = data['structure'];
    }
  }

  /// Limpa dados da sessão atual (salas, estrutura, etc.)
  void clearSessionData() {
    if (Get.isRegistered<LocationService>()) {
      final locationService = Get.find<LocationService>();
      locationService.roomsOnFloor.clear();
      locationService.nearestStructure.value = null;
    }
  }

  /// Desconecta WebSocket e limpa todos os dados
  Future<void> disconnect() async {
    try {
      clearSessionData();
      
      if (isConnected.value) {
        await channel.sink.close(status.goingAway);
        isConnected.value = false;
      }
    } catch (e) {
      print('[WebSocketService] Erro ao desconectar: $e');
      isConnected.value = false;
    }
  }

  /// Remove sessionId do SharedPreferences (usado no logout)
  Future<void> clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
