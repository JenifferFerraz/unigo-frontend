import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import './storage_service.dart';
import '../models/user_model.dart';
import '../../core/config/env_service.dart';
import 'dart:convert';
import './location_service.dart';
import './websocket_service.dart';

class AuthService extends GetxService {
  final StorageService storage = Get.find<StorageService>();
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final dio = Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  final courses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourses();
  }
  /// Inicializa o serviço carregando dados do usuário do armazenamento local

  Future<AuthService> init() async {
    final userData = await storage.getUserData();
    if (userData != null) {
      currentUser.value = User.fromJson(userData);
    }
    return this;
  }
  /// Registra um novo usuário no sistema

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? avatar,
    required String role,
    required Map<String, dynamic> studentProfile,
    required bool termsAccepted,
  }) async {
    try {
      isLoading.value = true;
      
      final requestData = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'termsAccepted': termsAccepted,
        'studentProfile': studentProfile,
      };
      
      
      final response = await dio.post('/users', data: requestData);
      print('[REGISTER DEBUG] Backend response:');
      print(response.data);
      print('Status code: ${response.statusCode}');

      if (response.statusCode == 201 && response.data != null && response.data['id'] != null) {
        final userData = response.data;
        try {
          currentUser.value = User.fromJson(userData);
        } catch (e) {
          print('[REGISTER DEBUG] Erro ao converter User.fromJson: $e');
        }
        await storage.saveUserData(userData);
        return true;
      } else {
        print('[REGISTER DEBUG] Falha na validação do response:');
        print('response.data: ${response.data}');
        print('response.statusCode: ${response.statusCode}');
      }
      return false;
    } on DioException catch (e) {
      print('[REGISTER DEBUG] DioException: $e');
      if (e.response != null) {
        print('[REGISTER DEBUG] DioException response data: ${e.response?.data}');
        print('[REGISTER DEBUG] DioException status code: ${e.response?.statusCode}');
      }
      String errorMessage = 'Não foi possível criar a conta';
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        if (e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error'];
        }
      }
      Get.snackbar(
        'Erro',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      print('[REGISTER DEBUG] Exception: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível criar a conta',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  /// Gerencia permissões de localização e aceitação de termos

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final userData = response.data;
        currentUser.value = User.fromJson(userData);
        await storage.saveUserData(userData);

        if (userData['requiresTermsAcceptance'] == true) {
          Get.offAllNamed(AppRoutes.TERMS);
          return true;
        }
        
        // Inicializa LocationService após login
        if (Get.isRegistered<LocationService>()) {
          await Get.delete<LocationService>();
        }
        final locationService = Get.put(LocationService());
        await locationService.requestLocationPermission();
        
        // 🔥 Inicializa e conecta WebSocket após login bem-sucedido
        print('[AuthService] Inicializando WebSocket...');
        if (Get.isRegistered<WebSocketService>()) {
          await Get.delete<WebSocketService>();
        }
        final ws = Get.put(WebSocketService());
        await ws.connect();
        print('[AuthService] ✓ WebSocket conectado');
        
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        Get.snackbar(
          'Erro',
          'Email ou senha incorretos',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Ocorreu um erro ao fazer login',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      print('[AuthService] Iniciando logout...');
      
      // 1. Limpa dados de localização
      if (Get.isRegistered<LocationService>()) {
        final locationService = Get.find<LocationService>();
        locationService.clearAllData();
        print('[AuthService] ✓ LocationService limpo');
      }
      
      // 2. Desconecta e limpa WebSocket + SharedPreferences
      if (Get.isRegistered<WebSocketService>()) {
        final wsService = Get.find<WebSocketService>();
        await wsService.disconnect();
        await wsService.clearSessionId();
        print('[AuthService] ✓ WebSocket desconectado e sessionId removido');
      }
      
      // 3. Limpa dados de autenticação (FlutterSecureStorage)
      await storage.clearUserData();
      print('[AuthService] ✓ Storage limpo (user_data e token)');
      
      // 4. Limpa estado em memória
      currentUser.value = null;
      print('[AuthService] ✓ CurrentUser limpo');
      
      // 5. Navega para tela de seleção
      Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
      print('[AuthService] ✓ Logout completo');
    } catch (e) {
      print('[AuthService] ❌ Erro durante logout: $e');
      // Mesmo com erro, força logout completo
      try {
        await storage.clearUserData();
      } catch (_) {}
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
    }
  }
  /// Solicita permissão de localização ao usuário

  void _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      Get.offAllNamed(AppRoutes.HOME); 
    } else {
      Get.snackbar(
        'Permissão Necessária',
        'É necessário permitir o acesso à localização para usar o app.',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }
  /// Verifica se existe um usuário autenticado

  bool get isAuthenticated => currentUser.value != null;
  /// Inicia o processo de redefinição de senha

  Future<bool> resetPassword({required String email}) async {
    try {
      isLoading.value = true;
      
      final response = await dio.post('/auth/reset-password', data: {
        'email': email,
      });

      return response.statusCode == 200;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Ocorreu um erro ao enviar o email de recuperação',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> fetchCourses() async {
    try {
      final response = await dio.get('/api');
      if (response.statusCode == 200) {
        courses.value = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar a lista de cursos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


Future<void> handleLocationPermission() async {
  try {
    LocationService? locationService;
    
    if (Get.isRegistered<LocationService>()) {
      locationService = Get.find<LocationService>();
    } else {
      locationService = Get.put(LocationService());
    }
    
    if (locationService == null) {
      Get.snackbar(
        'Erro',
        'Não foi possível inicializar o serviço de localização',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    final hasPermission = await locationService.requestLocationPermission();
    
    if (hasPermission == true) {
      Get.offAllNamed('/home');
    } else {
      Get.snackbar(
        'Erro',
        'É necessário permitir o acesso à localização para usar o aplicativo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  } catch (e) {
    print('[AuthService] Erro ao solicitar permissão: $e');
    Get.snackbar(
      'Erro',
      'Ocorreu um erro ao solicitar permissão de localização',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
}