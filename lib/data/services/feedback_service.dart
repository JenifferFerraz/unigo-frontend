import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../../core/config/env_service.dart';
import '../../storage/token_storage.dart';
import './api_interceptor.dart';

class FeedbackService {
  final Dio _client;

  FeedbackService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: EnvService.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ))..interceptors.add(AuthInterceptor());

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

  /// Exportar estatísticas para CSV (apenas admin)
  Future<void> exportStatsCsv() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final res = await _client.get(
        '/api/feedback/stats/export/csv',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      if (res.statusCode == 200) {
        // Obter nome do arquivo do header Content-Disposition ou usar padrão
        String filename = 'feedback_stats.csv';
        final contentDisposition = res.headers.value('content-disposition');
        if (contentDisposition != null) {
          final match = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
          if (match != null) {
            filename = match.group(1) ?? filename;
          }
        }

        // Download do arquivo
        if (kIsWeb) {
          // Para web, usar universal_html
          final bytes = res.data as List<int>;
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', filename)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          // Para mobile, salvar usando path_provider (se disponível)
          // Por enquanto, apenas lança exceção informando que precisa implementar
          throw Exception('Download em mobile requer implementação adicional com path_provider');
        }
      } else {
        throw Exception('Erro ao exportar estatísticas');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao exportar estatísticas');
      }
      rethrow;
    }
  }
}
