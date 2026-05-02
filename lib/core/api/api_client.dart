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

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _getToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
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
