import 'package:dio/dio.dart';
import '../../core/config/env_service.dart';

class CalendarService {
  final Dio _client;

  CalendarService({Dio? client}) : _client = client ?? Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final res = await _client.get('/notifications/public-events');
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
