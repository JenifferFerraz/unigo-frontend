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
    return authService.currentUser.value != null
        ? RouteSettings(name: AppRoutes.HOME)
        : null;
  }
}