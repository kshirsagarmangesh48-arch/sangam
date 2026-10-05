import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: StorageKeys.accessToken);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: StorageKeys.refreshToken);
  }

  // Both tokens helper
  Future<void> saveTokens({required String token, required String refreshToken}) async {
    await Future.wait([
      saveAccessToken(token),
      saveRefreshToken(refreshToken),
    ]);
  }

  // User details cache (JSON)
  Future<void> saveUser(Map<String, dynamic> userMap) async {
    await _secureStorage.write(key: StorageKeys.currentUser, value: jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _secureStorage.read(key: StorageKeys.currentUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Clear all auth credentials
  Future<void> clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(key: StorageKeys.accessToken),
      _secureStorage.delete(key: StorageKeys.refreshToken),
      _secureStorage.delete(key: StorageKeys.currentUser),
    ]);
  }

  // Remembered Email (non-sensitive preferences)
  Future<void> saveRememberedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.rememberEmail, email);
  }

  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.rememberEmail);
  }
}
