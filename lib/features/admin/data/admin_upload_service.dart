import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/env_service.dart';
import '../../../storage/token_storage.dart';

class AdminUploadService {
  final Dio _dio;
  AdminUploadService([Dio? dio]) : _dio = dio ?? Dio();

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