import 'package:get/get.dart';
import '../../data/services/location_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/websocket_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocationService());
    Get.find<AuthService>();
    
    // Inicializa WebSocket para navegação (funciona para usuários autenticados e visitantes)
    if (!Get.isRegistered<WebSocketService>()) {
      final wsService = Get.put(WebSocketService());
      wsService.connect();
    }
  }
}