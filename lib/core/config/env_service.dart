import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class EnvService {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  /// Detecta automaticamente o ambiente e retorna a URL da API apropriada
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Flutter Web - usa localhost
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Verifica se está no emulador ou dispositivo físico
      if (_isAndroidEmulator()) {
        // Android Emulador - usa 10.0.2.2 (IP especial do emulador)
        return dotenv.env['API_URL_ANDROID_EMULATOR'] ?? 'http://10.0.2.2:3000';
      } else {
        // Android Dispositivo Físico - usa IP da máquina na rede local
        return dotenv.env['API_URL_ANDROID_DEVICE'] ?? 'http://192.168.1.100:3000';
      }
    } else if (Platform.isIOS) {
      // iOS - usa localhost (assumindo que está rodando na mesma máquina)
      return dotenv.env['API_URL'] ?? 'http://localhost:3000';
    } else {
      // Fallback para outros ambientes
      return dotenv.env['API_URL'] ?? 'http://localhost:3000';
    }
  }

  /// Detecta automaticamente o ambiente e retorna a URL do Socket apropriada
  static String get socketUrl {
    if (kIsWeb) {
      return dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      if (_isAndroidEmulator()) {
        return dotenv.env['SOCKET_URL_ANDROID_EMULATOR'] ?? 'http://10.0.2.2:3000';
      } else {
        return dotenv.env['SOCKET_URL_ANDROID_DEVICE'] ?? 'http://192.168.1.100:3000';
      }
    } else if (Platform.isIOS) {
      return dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
    } else {
      return dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
    }
  }

  /// Detecta se o Android está rodando no emulador
  static bool _isAndroidEmulator() {
    if (kIsWeb) return false; // Web não é Android
    
    try {
      // Verifica se está no emulador através de variáveis de ambiente
      final androidId = Platform.environment['ANDROID_ID'];
      final buildFingerprint = Platform.environment['BUILD_FINGERPRINT'];
      
      // Emuladores geralmente têm IDs específicos
      if (androidId != null && androidId.contains('generic')) {
        return true;
      }
      
      // Emuladores têm fingerprints específicos
      if (buildFingerprint != null && 
          (buildFingerprint.contains('generic') || 
           buildFingerprint.contains('sdk') ||
           buildFingerprint.contains('emulator'))) {
        return true;
      }
      
      // Fallback: assume que é dispositivo físico se não conseguir detectar
      return false;
    } catch (e) {
      // Em caso de erro, assume dispositivo físico
      return false;
    }
  }

  /// Retorna informações sobre o ambiente atual para debug
  static Map<String, String> get environmentInfo {
    if (kIsWeb) {
      return {
        'platform': 'Web',
        'isWeb': 'true',
        'isAndroid': 'false',
        'isIOS': 'false',
        'isEmulator': 'false',
        'apiBaseUrl': apiBaseUrl,
        'socketUrl': socketUrl,
      };
    } else {
      return {
        'platform': Platform.operatingSystem,
        'isWeb': 'false',
        'isAndroid': Platform.isAndroid.toString(),
        'isIOS': Platform.isIOS.toString(),
        'isEmulator': _isAndroidEmulator().toString(),
        'apiBaseUrl': apiBaseUrl,
        'socketUrl': socketUrl,
      };
    }
  }

  /// Imprime informações do ambiente no console para debug
  static void printEnvironmentInfo() {
    print('🌍 === INFORMAÇÕES DO AMBIENTE ===');
    print('📱 Plataforma: ${environmentInfo['platform']}');
    print('🌐 É Web: ${environmentInfo['isWeb']}');
    print('🤖 É Android: ${environmentInfo['isAndroid']}');
    print('🍎 É iOS: ${environmentInfo['isIOS']}');
    print('🎮 É Emulador: ${environmentInfo['isEmulator']}');
    print('🔗 API Base URL: ${environmentInfo['apiBaseUrl']}');
    print('📡 Socket URL: ${environmentInfo['socketUrl']}');
    print('=====================================');
  }
  
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static String get appName => dotenv.env['APP_NAME'] ?? 'UniGo';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
} 