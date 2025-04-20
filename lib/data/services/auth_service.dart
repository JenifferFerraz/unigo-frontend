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

  Future<AuthService> init() async {
    final userData = await storage.getUserData();
    if (userData != null) {
      print('Initializing with stored user data: ${jsonEncode(userData)}');
      currentUser.value = User.fromJson(userData);
    }
    return this;
  }

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
      
      final response = await dio.post('/users', data: {
        'name': name,
        'email': email,
        'password': password,
        'cpf': cpf,
        'avatar': avatar,
        'role': role,
        'studentProfile': studentProfile,
      });

      if (response.statusCode == 201) {
        final userData = response.data;
        print('Register response data: ${jsonEncode(userData)}');
        currentUser.value = User.fromJson(userData);
        await storage.saveUserData(userData);
        return true;
      }
      
      return false;
    } catch (e) {
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
        print('Login response data: ${jsonEncode(userData)}');
        
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

  Future<void> logout() async {
    await storage.clearUserData();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.LOGIN);
  }

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

  bool get isAuthenticated => currentUser.value != null;

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
      final response = await dio.get('/courses');
      if (response.statusCode == 200) {
        courses.value = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Erro ao buscar cursos: $e');
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
      print('Erro ao solicitar permissão de localização: $e');
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