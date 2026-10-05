import '../../../dashboard/data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

abstract class WalletDetailsRepository {
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
