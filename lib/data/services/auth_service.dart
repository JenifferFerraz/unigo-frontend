import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import './storage_service.dart';
import '../models/user_model.dart';
import '../../core/config/env_service.dart';

class AuthService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final _dio = Dio(BaseOptions(
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
    final userData = await _storage.getUser();
    if (userData != null) {
      currentUser.value = userData;
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
      
      final response = await _dio.post('/users', data: {
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
        currentUser.value = User.fromJson(userData);
        await _storage.saveUser(currentUser.value!);
        await _storage.saveToken(userData['token']);
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
      
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final userData = response.data;
        currentUser.value = User.fromJson(userData);
        await _storage.saveUser(currentUser.value!);
        await _storage.saveToken(userData['token']);
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
    await _storage.clearUser();
    await _storage.deleteToken();
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
      
      final response = await _dio.post('/auth/reset-password', data: {
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
      final response = await _dio.get('/courses');
      if (response.statusCode == 200) {
        courses.value = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Erro ao buscar cursos: $e');
    }
  }
} 