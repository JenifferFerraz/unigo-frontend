import 'package:dio/dio.dart';
import '../../core/config/env_service.dart';

class ExamService {
  final Dio _client;

  ExamService({Dio? client}) : _client = client ?? Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<Map<String, dynamic>>> getExams({int? cycle, String? shift, int? month, int? year}) async {
    try {
      final query = <String, dynamic>{};
      if (cycle != null) query['cycle'] = cycle.toString();
      if (shift != null && shift.isNotEmpty) query['shift'] = shift;
      if (month != null) query['month'] = month.toString();
      if (year != null) query['year'] = year.toString();

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
}
