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
    required String cpf,
    String? avatar,
    required String role,
    required Map<String, dynamic> studentProfile,
  }) async {
    try {
      isLoading.value = true;
      
      // Extrai o gender do studentProfile e adiciona diretamente no objeto principal
      final String? gender = studentProfile.remove('gender') as String?;
      
      final requestData = {
        'name': name,
        'email': email,
        'password': password,
        'cpf': cpf,
        'avatar': avatar,
        'role': role,
        'termsAccepted': false,
        if (gender != null) 'gender': gender,
        'studentProfile': studentProfile,
      };
      
      print('Enviando dados de registro: ${jsonEncode(requestData)}');
      
      final response = await dio.post('/users', data: requestData);

      if (response.statusCode == 201) {
        final userData = response.data;
        print('Register response data: ${jsonEncode(userData)}');
        currentUser.value = User.fromJson(userData);
        await storage.saveUserData(userData);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      print('Erro durante registro: ${e.response?.data ?? e.message}');
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
      print('Erro não esperado durante registro: $e');
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

        await handleLocationPermission();
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
  /// Limpa dados locais e redireciona para tela de login

  Future<void> logout() async {
    await storage.clearUserData();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.LOGIN);
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
  /// Busca a lista de cursos disponíveis da API
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
      final locationService = Get.find<LocationService>();
      final hasPermission = await locationService.requestLocationPermission();
      
      if (hasPermission) {
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