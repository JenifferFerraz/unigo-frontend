import 'package:dio/dio.dart';
import '../../../core/config/env_service.dart';
import '../../../storage/token_storage.dart';
import '../../../data/models/event_model.dart';

class EventApiService {
  final Dio _client;

  EventApiService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: EnvService.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ));

  Future<List<Event>> fetchEvents() async {
    final token = await TokenStorage.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final res = await _client.get(
      '/events',
      options: Options(headers: headers),
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = res.data;
      return data.map((e) => Event.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar eventos');
  }
}