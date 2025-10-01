import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class EnvService {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String _resolveLocalhost(String url) {
    if (!url.contains('localhost') && !url.contains('127.0.0.1')) return url;
    if (kIsWeb) return url; // Browser compartilha host da máquina
    try {
      if (Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      }
      // iOS Simulator aceita localhost. Para dispositivo físico, use IP da LAN no .env
      return url;
    } catch (_) {
      return url;
    }
  }

  static String get apiBaseUrl {
    final raw = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    return _resolveLocalhost(raw);
  }

  static String get socketUrl {
    final raw = dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
    return _resolveLocalhost(raw);
  }
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static String get appName => dotenv.env['APP_NAME'] ?? 'UniGo';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
} 