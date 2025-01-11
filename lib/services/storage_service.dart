import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

static Future<void> saveToken(String token) async {
  try {
    await _storage.write(key: 'jwt_token', value: token);
    debugPrint('Token saved successfully: $token');
  } catch (e) {
    debugPrint('Error saving token: $e');
    // Handle the error (e.g., log or show user message)
  }
}

  static Future<String?> getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    debugPrint('Retrieved token: $token');
    return token;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}

