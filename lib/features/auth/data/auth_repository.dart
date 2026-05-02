import 'package:shared_preferences/shared_preferences.dart';
import 'package:sangam_expense/core/api/api_client.dart';

class AuthRepository {
  final ApiClient apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.post('/sangam-home/auth/login', {
      'email': email,
      'password': password,
    });

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['data']['token']);
      await prefs.setString('user_name', response['data']['user']['name']);
      await prefs.setString('user_email', response['data']['user']['email']);
      await prefs.setString('user_role', response['data']['user']['role']);
      await prefs.setInt('user_id', response['data']['user']['id']);
    }

    return response;
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    return await apiClient.post('/sangam-home/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'role': prefs.getString('user_role'),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
