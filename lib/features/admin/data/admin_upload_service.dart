import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/env_service.dart';

class AdminUploadService {
  final Dio _dio;
  AdminUploadService([Dio? dio]) : _dio = dio ?? Dio();

  Future<Response> uploadSpreadsheet({
    required String endpoint,
    required PlatformFile file,
  }) async {
    final filePath = file.path;
    if (filePath == null) throw Exception('Caminho do arquivo não disponível');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: file.name),
    });

    final url = EnvService.apiBaseUrl + endpoint;
    return await _dio.post(
      url,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }
}
