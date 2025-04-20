import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class StorageService extends GetxService {
  final _storage = const FlutterSecureStorage();

  Future<StorageService> init() async {
    return this;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userDataString = jsonEncode(userData);
      await _storage.write(
        key: 'user_data',
        value: userDataString,
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataJson = await _storage.read(
        key: 'user_data',
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      
      if (userDataJson != null) {
        return jsonDecode(userDataJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUser() async {
    final data = await getUserData();
    if (data != null) {
      return User.fromJson(data);
    }
    return null;
  }

  Future<String?> getToken() async {
    final data = await getUserData();
    return data?['token'];
  }

  Future<String?> getRefreshToken() async {
    final data = await getUserData();
    return data?['refreshToken'];
  }

  Future<void> clearUserData() async {
    try {
      await _storage.delete(
        key: 'user_data',
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
} 