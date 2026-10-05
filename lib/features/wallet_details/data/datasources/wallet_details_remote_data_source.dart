import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../dashboard/data/models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

abstract class WalletDetailsRemoteDataSource {
  Future<WalletTransactionsResult> getWalletTransactions({
    required int accountId,
    String? type,
    String? startDate,
    int page = 1,
    int limit = 50,
  });

  Future<SangamAccount> updateAccount({
    required int id,
    required String name,
    String? description,
    bool? isActive,
  });

  Future<SangamTransaction> createTransaction({
    required double amount,
    required String type,
    required int accountId,
    int? categoryId,
    String? description,
    DateTime? date,
    int? spentById,
    int? paidById,
  });

  Future<List<SangamCategory>> getCategories();
  Future<List<SangamMemberRef>> getMembers();
  Future<List<SangamAccount>> getAccounts();

  Future<SangamCategory> createCategory({
    required String name,
    required String type,
    int? accountId,
  });
}

class WalletDetailsRemoteDataSourceImpl
    implements WalletDetailsRemoteDataSource {
  final ApiClient _apiClient;
  Map<int, String>? _cachedMemberNames;
  Map<int, SangamCategory>? _cachedCategories;

  WalletDetailsRemoteDataSourceImpl(this._apiClient);

  Future<Map<int, SangamCategory>> _getCategoriesMap() async {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    final map = <int, SangamCategory>{};
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.categories);
      if (response.data != null && response.data['data'] is List) {
        for (final item in response.data['data']) {
          if (item is Map<String, dynamic> && item['id'] != null) {
            map[item['id'] as int] = SangamCategory.fromJson(item);
          }
        }
      }
      _cachedCategories = map;
    } catch (_) {}
    return map;
  }

  Future<Map<int, String>> _getMemberNamesMap() async {
    if (_cachedMemberNames != null && _cachedMemberNames!.isNotEmpty) {
      return _cachedMemberNames!;
    }
    final map = <int, String>{};
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.members);
      if (response.data != null && response.data['data'] is List) {
        for (final item in response.data['data']) {
          if (item is Map && item['id'] != null && item['name'] != null) {
            map[item['id'] as int] = item['name'].toString();
          }
        }
      }
      _cachedMemberNames = map;
    } catch (_) {}
    return map;
  }

  @override
  Future<WalletTransactionsResult> getWalletTransactions({
    required int accountId,
    String? type,
    String? startDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'accountId': accountId,
        'page': page,
        'limit': limit,
      };
      if (type != null && type.isNotEmpty && type != 'ALL') {
        queryParams['type'] = type;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final rawList = data['data'] as List<dynamic>? ?? [];
        final transactions = rawList
            .map((item) =>
                SangamTransaction.fromJson(item as Map<String, dynamic>))
            .toList();

        final memberMap = await _getMemberNamesMap();
        final categoryMap = await _getCategoriesMap();

        // Also supplement from transactions if any member missing
        for (int i = 0; i < transactions.length; i++) {
          final t = transactions[i];
          if (t.spentBy != null) memberMap[t.spentBy!.id] = t.spentBy!.name;
          if (t.paidBy != null) memberMap[t.paidBy!.id] = t.paidBy!.name;
          if (t.recordedBy != null) memberMap[t.recordedBy!.id] = t.recordedBy!.name;
          if (t.category == null && t.categoryId != null && categoryMap.containsKey(t.categoryId)) {
            transactions[i] = t.copyWith(category: categoryMap[t.categoryId]);
          }
        }

        WalletFilterStats? filterStats;
        if (data['filterStats'] != null && data['filterStats'] is Map) {
          filterStats = WalletFilterStats.fromJson(
            data['filterStats'] as Map<String, dynamic>,
            memberNamesMap: memberMap,
          );
        }

        final pagination = data['pagination'] as Map<String, dynamic>?;
        final total =
            (pagination?['total'] as num?)?.toInt() ?? transactions.length;

        return WalletTransactionsResult(
          transactions: transactions,
          filterStats: filterStats,
          totalCount: total,
        );
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to load wallet transactions',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to fetch transactions'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SangamAccount> updateAccount({
    required int id,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
      };
      if (description != null) {
        payload['description'] = description.trim();
      }
      if (isActive != null) {
        payload['isActive'] = isActive;
      }

      final response = await _apiClient.dio.put(
        '${ApiEndpoints.accounts}/$id',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return SangamAccount.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to update wallet',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to update wallet'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SangamTransaction> createTransaction({
    required double amount,
    required String type,
    required int accountId,
    int? categoryId,
    String? description,
    DateTime? date,
    int? spentById,
    int? paidById,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'type': type,
        'accountId': accountId,
      };
      if (categoryId != null) payload['categoryId'] = categoryId;
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }
      if (date != null) {
        payload['date'] = date.toIso8601String();
      }
      if (spentById != null) payload['spentById'] = spentById;
      if (paidById != null) payload['paidById'] = paidById;

      final response = await _apiClient.dio.post(
        ApiEndpoints.transactions,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return SangamTransaction.fromJson(
            data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to record transaction',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to record transaction'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<SangamCategory>> getCategories() async {
    final map = await _getCategoriesMap();
    return map.values.toList();
  }

  @override
  Future<List<SangamMemberRef>> getMembers() async {
    final map = await _getMemberNamesMap();
    return map.entries
        .map((e) => SangamMemberRef(id: e.key, name: e.value))
        .toList();
  }

  @override
  Future<List<SangamAccount>> getAccounts() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.accounts);
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List<dynamic>? ?? [];
        return list
            .map((item) =>
                SangamAccount.fromJson(item as Map<String, dynamic>))
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
  Future<SangamCategory> createCategory({
    required String name,
    required String type,
    int? accountId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'type': type,
        'accountId': ?accountId,
      };

      final response = await _apiClient.dio.post(
        ApiEndpoints.categories,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        _cachedCategories = null; // Invalidate cache so newly created category is fetched next time
        return SangamCategory.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to create category',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to create category'),
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
