import '../../data/models/account_model.dart';

abstract class DashboardRepository {
  Future<List<SangamAccount>> getAccounts();
  Future<SangamAccount> createAccount({
    required String name,
    String? description,
    double balance = 0.0,
  });
}
