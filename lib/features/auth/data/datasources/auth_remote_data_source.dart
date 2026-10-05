import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_tokens.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResult> login({required String email, required String password});
  Future<AuthTokens> refreshToken(String refreshToken);
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return LoginResult.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, defaultMsg: 'Failed to connect to login server');
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
        details: e.response?.data,
      );
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return AuthTokens.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to refresh token',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, defaultMsg: 'Token refresh error');
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] != true) {
        throw ApiException(
          message: data['message'] ?? 'Failed to update password',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, defaultMsg: 'Failed to change password');
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String defaultMsg}) {
    if (e.response?.data != null && e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map.containsKey('message') && map['message'] != null) {
        return map['message'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to reach backend server. Please verify network or API URL.';
    }
    return e.message ?? defaultMsg;
  }
}
