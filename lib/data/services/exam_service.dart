import 'package:dio/dio.dart';
import '../../core/config/env_service.dart';
import '../../storage/token_storage.dart';
import './api_interceptor.dart';

class ExamService {
  final Dio _client;

  ExamService({Dio? client}) : _client = client ?? Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(AuthInterceptor());

  Future<List<Map<String, dynamic>>> getExams({int? cycle, String? shift, int? month, int? year, String? courseId}) async {
    try {
      final query = <String, dynamic>{};
      if (cycle != null) query['cycle'] = cycle.toString();
      if (shift != null && shift.isNotEmpty) query['shift'] = shift;
      if (month != null) query['month'] = month.toString();
      if (year != null) query['year'] = year.toString();
      if (courseId != null && courseId.isNotEmpty) query['courseId'] = courseId;

      final res = await _client.get('/exams', queryParameters: query);
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Buscar horários (schedules)
  Future<List<Map<String, dynamic>>> getSchedules({String? course, String? shift, int? semester}) async {
    try {
      final query = <String, dynamic>{};
      if (course != null) query['course'] = course;
      if (shift != null) query['shift'] = shift;
      if (semester != null) query['semester'] = semester.toString();

      final res = await _client.get('/schedules', queryParameters: query);
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Buscar eventos
  Future<List<Map<String, dynamic>>> getEvents({String? type, bool? isActive}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null) query['type'] = type;
      if (isActive != null) query['isActive'] = isActive.toString();

      final res = await _client.get('/events', queryParameters: query);
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// Buscar calendário acadêmico
  Future<List<Map<String, dynamic>>> getAcademicCalendar({String? type, int? semester, int? year}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null) query['type'] = type;
      if (semester != null) query['semester'] = semester.toString();
      if (year != null) query['year'] = year.toString();

      final res = await _client.get('/academic-calendar', queryParameters: query);
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      rethrow;
    }
  }
}
