import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3002';
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? 'http://localhost:3002';
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static String get appName => dotenv.env['APP_NAME'] ?? 'UniGo';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
} 