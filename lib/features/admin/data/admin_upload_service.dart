import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/env_service.dart';
import '../../../storage/token_storage.dart';

class AdminUploadService {
  final Dio _dio;
  AdminUploadService([Dio? dio]) : _dio = dio ?? Dio();

  /// Buscar provas recentes
  Future<List<Map<String, dynamic>>> getRecentExams() async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/exams';
    final response = await _dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Buscar horários recentes
  Future<List<Map<String, dynamic>>> getRecentSchedules() async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/schedules';
    final response = await _dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    
    // O backend retorna: {periods: 0, schedules: [...]}
    // Precisamos extrair apenas a lista de schedules
    if (response.data is Map && response.data.containsKey('schedules')) {
      return List<Map<String, dynamic>>.from(response.data['schedules']);
    }
    
    // Fallback: se vier como lista diretamente
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Buscar eventos recentes
  Future<List<Map<String, dynamic>>> getRecentEvents() async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/events';
    final response = await _dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Buscar calendário recente
  Future<List<Map<String, dynamic>>> getRecentCalendars() async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/api/academic-calendar';
    final response = await _dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> updateExam({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/exams/$id';
    final response = await _dio.patch(
      url,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Atualiza dados de um horário existente
  Future<Map<String, dynamic>> updateSchedule({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/schedules/$id';
    final response = await _dio.put(
      url,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Atualiza dados de um evento existente
  Future<Map<String, dynamic>> updateEvent({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/events/$id';
    final response = await _dio.patch(
      url,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Deleta uma prova existente
  Future<void> deleteExam(String id) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/exams/$id';
    await _dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Deleta um horário existente
  Future<void> deleteSchedule(String id) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/schedules/$id';
    await _dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Deleta um evento existente
  Future<void> deleteEvent(String id) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/events/$id';
    await _dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Deleta um evento do calendário existente
  Future<void> deleteCalendar(String id) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/api/academic-calendar/$id';
    await _dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Atualiza dados de um calendário existente
  Future<Map<String, dynamic>> updateCalendar({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token não encontrado');
    final url = EnvService.apiBaseUrl + '/api/academic-calendar/$id';
    final response = await _dio.put(
      url,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Response> uploadSpreadsheet({
    required String endpoint,
    required PlatformFile file,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      MultipartFile multipartFile;
      FormData formData;

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Bytes do arquivo não disponíveis na web');
        }
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
        formData = FormData.fromMap({
          'file': multipartFile,
        });
      } else {
        final filePath = file.path;
        if (filePath == null) {
          throw Exception('Caminho do arquivo não disponível');
        }
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: file.name,
        );
        formData = FormData.fromMap({
          'file': multipartFile,
        });
      }

      final url = EnvService.apiBaseUrl + endpoint;
      return await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('path') && errorStr.contains('null')) {
        throw Exception('Erro ao processar arquivo na web. Por favor, certifique-se de que o arquivo foi selecionado com withData: true e tente novamente.');
      }
      rethrow;
    }
  }

  /// Upload de horários
  Future<Map<String, dynamic>> uploadSchedule(PlatformFile file) async {
    final res = await uploadSpreadsheet(
      endpoint: '/upload/schedule',
      file: file,
    );
    return res.data as Map<String, dynamic>;
  }

  /// Upload de eventos
  Future<Map<String, dynamic>> uploadEvents(PlatformFile file) async {
    final res = await uploadSpreadsheet(
      endpoint: '/upload/events',
      file: file,
    );
    return res.data as Map<String, dynamic>;
  }

  /// Upload de calendário
  Future<Map<String, dynamic>> uploadCalendar(PlatformFile file) async {
    final res = await uploadSpreadsheet(
      endpoint: '/upload/calendar',
      file: file,
    );
    return res.data as Map<String, dynamic>;
  }

  /// Upload de provas
  Future<Map<String, dynamic>> uploadExams(PlatformFile file) async {
    final res = await uploadSpreadsheet(
      endpoint: '/upload/exams',
      file: file,
    );
    return res.data as Map<String, dynamic>;
  }

  /// Download de template
  Future<Response> downloadTemplate(String type) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token não encontrado');

      final url = '${EnvService.apiBaseUrl}/upload/template/$type';
      return await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}