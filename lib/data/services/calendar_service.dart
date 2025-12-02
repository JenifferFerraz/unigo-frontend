import 'package:dio/dio.dart';
import '../../core/config/env_service.dart';
import '../../storage/token_storage.dart';

class CalendarService {
  final Dio _client;

  CalendarService({Dio? client}) : _client = client ?? Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<Map<String, dynamic>>> getCalendarEvents({
    int? month,
    int? year,
    String? type,
    bool? isActive,
    int? semester,
    String? course,
    String? courseId,
    String? role,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (month != null) query['month'] = month.toString();
      if (year != null) query['year'] = year.toString();
      if (type != null && type.isNotEmpty) query['type'] = type;
      if (isActive != null) query['isActive'] = isActive.toString();
      if (semester != null) query['semester'] = semester.toString();
      if (course != null && course.isNotEmpty) query['course'] = course;

      // Sempre envia courseId se estiver definido
      if (courseId == null || courseId.isEmpty) {
        courseId = await TokenStorage.getCourseId();
      }
      if (courseId != null && courseId.isNotEmpty) {
        query['courseId'] = courseId;
      }


      final token = await TokenStorage.getToken();
      final res = await _client.get(
        '/api/academic-calendar',
        queryParameters: query,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (res.statusCode == 200) {
        final data = res.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final token = await TokenStorage.getToken();
      final dio = Dio(BaseOptions(
        baseUrl: EnvService.apiBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      final res = await dio.get('/api');
      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (e) {
      print('Erro ao buscar cursos: $e');
      return [];
    }
  }
}
