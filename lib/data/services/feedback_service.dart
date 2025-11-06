import 'package:dio/dio.dart';
import '../../core/config/env_service.dart';
import '../../storage/token_storage.dart';

class FeedbackService {
  final Dio _client;

  FeedbackService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: EnvService.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ));

  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final token = await TokenStorage.getToken();

      final headers = <String, String>{'Content-Type': 'application/json'};
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      // Se não tiver token, feedback será anônimo

      final res = await _client.post(
        '/api/feedback',
        data: feedbackData,
        options: Options(headers: headers),
      );

      if (res.statusCode == 201) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao enviar feedback');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao enviar feedback');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final res = await _client.get(
        '/api/feedback/stats',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao buscar estatísticas');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao buscar estatísticas');
      }
      rethrow;
    }
  }

  /// Listar todos os feedbacks (apenas admin)
  Future<List<Map<String, dynamic>>> listFeedbacks({
    String? vinculo,
    bool? isAnonymous,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final query = <String, dynamic>{};
      if (vinculo != null) query['vinculo'] = vinculo;
      if (isAnonymous != null) query['isAnonymous'] = isAnonymous.toString();
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;

      final res = await _client.get(
        '/api/feedback',
        queryParameters: query,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Erro ao listar feedbacks');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao listar feedbacks');
      }
      rethrow;
    }
  }
}
