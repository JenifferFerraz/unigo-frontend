import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static Future<void> init() async {}

  static String get apiBaseUrl {
    if (kIsWeb) {
      return const String.fromEnvironment('API_URL', 
          defaultValue: 'https://unigo-backend.onrender.com');
    }
    return const String.fromEnvironment('API_URL', 
        defaultValue: 'http://localhost:3000');
  }

  static String get socketUrl {
    if (kIsWeb) {
      return const String.fromEnvironment('SOCKET_URL', 
          defaultValue: 'wss://unigo-backend.onrender.com');
    }
    return const String.fromEnvironment('SOCKET_URL', 
        defaultValue: 'ws://localhost:3000');
  }

  static String get cloudName =>
      const String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'Teste_UniGo');

  static String get cloudKey =>
      const String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '');

  static String get appName =>
      const String.fromEnvironment('APP_NAME', defaultValue: 'UniGo');

  static String get appEnv =>
      const String.fromEnvironment('APP_ENV', defaultValue: 'development');
}
