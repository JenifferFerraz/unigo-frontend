import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/config/env_service.dart';
import '../../storage/token_storage.dart';

class UploadService {
  final Dio _client;

  UploadService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: EnvService.apiBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'multipart/form-data'},
            ));

  /// Upload de horários (schedules)
  Future<Map<String, dynamic>> uploadSchedule(PlatformFile file) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final res = await _client.post(
        '/upload/schedule',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao fazer upload');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao fazer upload');
      }
      rethrow;
    }
  }

  /// Upload de eventos (events)
  Future<Map<String, dynamic>> uploadEvents(PlatformFile file) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final res = await _client.post(
        '/upload/events',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao fazer upload');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao fazer upload');
      }
      rethrow;
    }
  }

  /// Upload de calendário acadêmico (calendar)
  Future<Map<String, dynamic>> uploadCalendar(PlatformFile file) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final res = await _client.post(
        '/upload/calendar',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao fazer upload');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao fazer upload');
      }
      rethrow;
    }
  }

  /// Upload de provas (exams)
  Future<Map<String, dynamic>> uploadExams(PlatformFile file) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final res = await _client.post(
        '/upload/exams',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Erro ao fazer upload');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Erro ao fazer upload');
      }
      rethrow;
    }
  }

  /// Download de template
  Future<void> downloadTemplate(String type, String savePath) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final res = await _client.get(
        '/upload/template/$type',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      if (res.statusCode == 200) {
        // Salvar arquivo usando package:universal_html ou file_saver
        // Implementar conforme necessidade da plataforma (web/mobile)
        return;
      }
      throw Exception('Erro ao baixar template');
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception('Erro ao baixar template');
      }
      rethrow;
    }
  }
}
