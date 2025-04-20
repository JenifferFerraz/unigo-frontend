import 'package:get/get.dart';
import '../../data/services/location_service.dart';
import '../../data/services/auth_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocationService());
    Get.find<AuthService>(); 
  }
}