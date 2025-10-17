import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    return authService.currentUser.value == null
        ? RouteSettings(name: AppRoutes.LOGIN)
        : null;
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    if (Get.arguments != null && Get.arguments['visitor'] == true) {
      Get.put<bool>(true, tag: 'visitor'); 
    } else {
      if (Get.isRegistered<bool>(tag: 'visitor')) {
        Get.delete<bool>(tag: 'visitor');
      }
    }
    bool isVisitor() => Get.isRegistered<bool>(tag: 'visitor') && Get.find<bool>(tag: 'visitor');
    bool isAdmin() {
      final authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      return authService?.currentUser.value?.role == 'admin';
    }
   
    return authService.currentUser.value != null
        ? RouteSettings(name: AppRoutes.HOME)
        : null;
  }
}