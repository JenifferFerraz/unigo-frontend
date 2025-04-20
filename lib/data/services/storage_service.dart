import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class StorageService extends GetxService {
  final _storage = const FlutterSecureStorage();

  Future<StorageService> init() async {
    return this;
  }

  Future<void> saveUser(User user) async {
    try {
      await _storage.write(
        key: 'user',
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      await _storage.delete(key: 'user');
    } catch (e) {
      print('Error clearing user: $e');
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }
} 