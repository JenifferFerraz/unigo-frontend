import 'package:get/get.dart';
import '../data/services/storage_service.dart';

/// Classe utilitária para acesso ao token de autenticação
/// Wrapper estático sobre o StorageService
class TokenStorage {
  /// Obtém o token de autenticação do armazenamento seguro
  static Future<String?> getToken() async {
    try {
      final storageService = Get.find<StorageService>();
      
      // Primeiro tenta obter do cache em memória
      if (storageService.token.value != null) {
        return storageService.token.value;
      }
      
      // Se não tiver em memória, busca do armazenamento seguro
      final userData = await storageService.getUserData();
      if (userData != null && userData['token'] != null) {
        return userData['token'] as String;
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  /// Salva o token de autenticação no armazenamento seguro
  static Future<void> setToken(String token, Map<String, dynamic> userData) async {
    try {
      final storageService = Get.find<StorageService>();
      await storageService.saveUserData({
        ...userData,
        'token': token,
      });
    } catch (e) {
      print('Erro ao salvar token: $e');
      rethrow;
    }
  }

  /// Remove o token de autenticação (logout)
  static Future<void> removeToken() async {
    try {
      final storageService = Get.find<StorageService>();
      await storageService.clearUserData();
    } catch (e) {
      print('Erro ao remover token: $e');
      rethrow;
    }
  }

  /// Verifica se existe um token válido
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
