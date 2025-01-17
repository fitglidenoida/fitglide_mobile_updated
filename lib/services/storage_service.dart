import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {

static Future<void> saveToken(String token) async {
  try {
    await _storage.write(key: 'jwt_token', value: token);
    debugPrint('Token saved successfully: $token');
  } catch (e) {
    debugPrint('Error saving token: $e');
    // Handle the error (e.g., log or show user message)
  }
}

static const _storage = FlutterSecureStorage();
  static Future<void> saveData(String key, String? value) async {
    try {
      if (value != null) {
        await _storage.write(key: key, value: value);
        debugPrint('$key saved successfully: $value');
      }
    } catch (e) {
      debugPrint('Error saving $key: $e');
    }
  }


    /// Retrieve a string value from secure storage
  static Future<String?> getData(String key) async {
    try {
      final value = await _storage.read(key: key);
      debugPrint('Retrieved $key: $value');
      return value;
    } catch (e) {
      debugPrint('Error retrieving $key: $e');
      return null;
    }
  }


  static Future<String?> getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    debugPrint('Retrieved token: $token');
    return token;
  }

    /// Remove a specific key from secure storage
  static Future<void> removeData(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('$key removed successfully');
    } catch (e) {
      debugPrint('Error removing $key: $e');
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}

