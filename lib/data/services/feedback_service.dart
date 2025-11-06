import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../core/config/env_service.dart';
import 'storage_service.dart';

class FeedbackService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: EnvService.apiBaseUrl,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<bool> createFeedback(Map<String, dynamic> payload) async {
    try {
      String? token;
      try {
        final storageService = Get.find<StorageService>();
        token = await storageService.getToken();
      } catch (e) {
        token = null;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Adiciona o token de autenticação se disponível
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Envia o feedback para o backend
      final response = await _dio.post(
        '/api/feedback',
        data: payload,
        options: Options(headers: headers),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      // Tratamento de erro do Dio
      // Log pode ser adicionado aqui se necessário para debug
      return false;
    } catch (_) {
      // Tratamento para outros tipos de erro
      return false;
    }
  }
}


