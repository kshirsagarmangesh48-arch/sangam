import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'http://206.189.136.110/api/v1'; // Remote Production Server

  // Use a persistent client to enable connection reuse (Keep-Alive)
  static final http.Client _client = http.Client();
  static Completer<bool>? _refreshCompleter;
  static VoidCallback? onSessionExpired;

  Future<bool> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final url = Uri.parse('$baseUrl/sangam-home/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Accommodate possible response structures
        final newAccessToken = data['data']?['token'] ?? data['token'];
        final newRefreshToken = data['data']?['refreshToken'] ?? data['refreshToken'];

        if (newAccessToken != null) {
          await prefs.setString('access_token', newAccessToken);
        }
        if (newRefreshToken != null) {
          await prefs.setString('refresh_token', newRefreshToken);
        }
        
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        // Clear prefs on failure to force logout
        await prefs.clear();
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        onSessionExpired?.call();
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Refresh token error: $e');
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      onSessionExpired?.call();
      return false;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('POST', url, body);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      _logResponse('POST', url, response);

      if (response.statusCode == 401 && !endpoint.contains('/auth/login')) {
        final success = await _refreshToken();
        if (success) {
          final newToken = prefs.getString('access_token');
          final retryResponse = await _client.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 10));
          
          _logResponse('POST Retry', url, retryResponse);
          return _processResponse(retryResponse);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Please check if your backend is running.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('PUT', url, body);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await _client
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      _logResponse('PUT', url, response);

      if (response.statusCode == 401) {
        final success = await _refreshToken();
        if (success) {
          final newToken = prefs.getString('access_token');
          final retryResponse = await _client.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 10));
          
          _logResponse('PUT Retry', url, retryResponse);
          return _processResponse(retryResponse);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Please check if your backend is running.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParameters != null) {
      // Filter out null values and convert everything to string
      final cleanParams = queryParameters.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value.toString()));

      uri = uri.replace(queryParameters: Map.fromEntries(cleanParams));
    }

    _logRequest('GET', uri, null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      _logResponse('GET', uri, response);

      if (response.statusCode == 401) {
        final success = await _refreshToken();
        if (success) {
          final newToken = prefs.getString('access_token');
          final retryResponse = await _client.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 10));
          
          _logResponse('GET Retry', uri, retryResponse);
          return _processResponse(retryResponse);
        }
      }

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Please check if your backend is running.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _getToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 401) {
      final success = await _refreshToken();
      if (success) {
        final newToken = await _getToken();
        final retryResponse = await _client.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (newToken != null) 'Authorization': 'Bearer $newToken',
          },
        );
        return _handleResponse(retryResponse);
      }
    }
    
    return _handleResponse(response);
  }

  void _logRequest(String method, Uri url, dynamic body) {
    if (kDebugMode) {
      print('🚀 API Request: $method $url');
      if (body != null) print('📦 Body: ${jsonEncode(body)}');
    }
  }

  void _logResponse(String method, Uri url, http.Response response) {
    if (kDebugMode) {
      print('✅ API Response: ${response.statusCode} $url');
      print('📄 Response: ${response.body}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    return _processResponse(response);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server error: Received non-JSON response (${response.statusCode}). Check your API URL.',
      );
    }

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Something went wrong');
    }
  }
}
