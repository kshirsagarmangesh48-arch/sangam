import 'package:sangam_expense/core/api/api_client.dart';

class ExpenseRepository {
  final ApiClient apiClient = ApiClient();

  Future<Map<String, dynamic>> getStats([Map<String, dynamic>? filters]) async {
    String query = '';
    if (filters != null) {
      final queryParams = <String>[];
      filters.forEach((key, value) {
        if (value != null) {
          queryParams.add('$key=$value');
        }
      });
      if (queryParams.isNotEmpty) {
        query = '?${queryParams.join('&')}';
      }
    }
    return await apiClient.get('/sangam-home/stats$query');
  }

  Future<List<dynamic>> getAccounts() async {
    final response = await apiClient.get('/sangam-home/accounts');
    return response['data'];
  }

  Future<void> createAccount(String name, String description) async {
    await apiClient.post('/sangam-home/accounts', {
      'name': name,
      'description': description,
    });
  }

  Future<void> updateAccount(int id, String name, String description) async {
    await apiClient.put('/sangam-home/accounts/$id', {
      'name': name,
      'description': description,
    });
  }

  Future<List<dynamic>> getCategories() async {
    final response = await apiClient.get('/sangam-home/categories');
    return response['data'];
  }

  Future<void> createCategory(String name, String type, {int? accountId}) async {
    await apiClient.post('/sangam-home/categories', {
      'name': name,
      'type': type,
      'accountId': accountId,
    });
  }

  Future<void> updateCategory(int id, String name, String type, bool isActive, {int? accountId}) async {
    await apiClient.put('/sangam-home/categories/$id', {
      'name': name,
      'type': type,
      'isActive': isActive,
      'accountId': accountId,
    });
  }

  Future<void> deleteCategory(int id) async {
    await apiClient.delete('/sangam-home/categories/$id');
  }

  Future<List<dynamic>> getFamilyMembers() async {
    final response = await apiClient.get('/sangam-home/members');
    return response['data'];
  }

  Future<Map<String, dynamic>> getTransactions([Map<String, dynamic>? filters]) async {
    final response = await apiClient.get('/sangam-home/transactions', queryParameters: filters);
    return response;
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    await apiClient.post('/sangam-home/transactions', data);
  }

  Future<void> updateTransaction(int id, Map<String, dynamic> data) async {
    await apiClient.put('/sangam-home/transactions/$id', data);
  }

  Future<void> deleteTransaction(int id) async {
    await apiClient.delete('/sangam-home/transactions/$id');
  }
}
