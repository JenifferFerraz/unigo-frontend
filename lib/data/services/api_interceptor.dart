import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import './auth_service.dart';


class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _handleUnauthorized();
    }
    
    super.onError(err, handler);
  }

  void _handleUnauthorized() async {
    try {
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        
        authService.currentUser.value = null;
        await authService.storage.clearUserData();
        
        final currentRoute = Get.currentRoute;
        if (currentRoute != AppRoutes.ACCESS_SELECTION &&
            currentRoute != AppRoutes.LOGIN &&
            currentRoute != AppRoutes.REGISTER) {
          Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
        }
      }
    } catch (e) {
      print('Erro ao processar 401: $e');
    }
  }
}
