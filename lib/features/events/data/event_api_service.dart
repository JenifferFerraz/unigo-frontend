import 'package:dio/dio.dart';
import '../../../core/config/env_service.dart';
import '../../../storage/token_storage.dart';
import '../../../data/models/event_model.dart';
import '../../../data/services/api_interceptor.dart';

class EventApiService {
  final Dio _client;

  EventApiService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: EnvService.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ))..interceptors.add(AuthInterceptor());

  Future<List<Event>> fetchEvents({String? courseId}) async {
    final token = await TokenStorage.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final query = <String, dynamic>{};
    if (courseId != null && courseId.isNotEmpty) {
      query['courseId'] = courseId;
    }

    final res = await _client.get(
      '/events',
      queryParameters: query,
      options: Options(headers: headers),
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = res.data;
      return data.map((e) => Event.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar eventos');
  }

  Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final token = await TokenStorage.getToken();
      final dio = Dio(BaseOptions(
        baseUrl: EnvService.apiBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ))..interceptors.add(AuthInterceptor());
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