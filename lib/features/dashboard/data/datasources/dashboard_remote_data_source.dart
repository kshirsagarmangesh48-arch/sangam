import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/account_model.dart';

abstract class DashboardRemoteDataSource {
  Future<List<SangamAccount>> getAccounts();
  Future<SangamAccount> createAccount({
    required String name,
    String? description,
    double balance = 0.0,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SangamAccount>> getAccounts() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.accounts,
        options: Options(
          extra: {
            'noCache': true,
            'refresh': true,
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List<dynamic>? ?? [];
        return list
            .map((item) => SangamAccount.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to load accounts',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to fetch family wallets'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SangamAccount> createAccount({
    required String name,
    String? description,
    double balance = 0.0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.accounts,
        data: {
          'name': name.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          'balance': balance,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return SangamAccount.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to create wallet',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to create wallet'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map.containsKey('message') && map['message'] != null) {
        return map['message'].toString();
      }
    }
    return e.message ?? defaultMessage;
  }
}
