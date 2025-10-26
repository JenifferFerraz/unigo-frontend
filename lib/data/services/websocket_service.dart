
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
    print('[WebSocketService] Tentando enviar: '
        + jsonEncode(data));
    if (isConnected.value) {
      channel.sink.add(jsonEncode(data));
      print('[WebSocketService] Enviado com sucesso!');
    } else {
      print('[WebSocketService] Não está conectado ao WebSocket.');
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
    print('[WebSocketService] Chamando sendPosition: $data');
    send(data);
  }

  void _handleMessage(dynamic message) {
    print('[WebSocketService] Mensagem recebida: $message');
    final data = jsonDecode(message);
    final locationService = Get.find<LocationService>();
    if (data['type'] == 'roomsOnFloor') {
      if (data['rooms'] is List) {
        locationService.roomsOnFloor.assignAll(List<Map<String, dynamic>>.from(data['rooms']));
      }
    } else if (data['type'] == 'nearestStructure') {
      locationService.nearestStructure.value = data['structure'];
    }
  }

  @override
  void onClose() {
    channel.sink.close(status.goingAway);
    super.onClose();
  }
}
