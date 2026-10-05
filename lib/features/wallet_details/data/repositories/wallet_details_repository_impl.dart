import '../../../dashboard/data/models/account_model.dart';
import '../../domain/repositories/wallet_details_repository.dart';
import '../datasources/wallet_details_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class WalletDetailsRepositoryImpl implements WalletDetailsRepository {
  final WalletDetailsRemoteDataSource remoteDataSource;

  WalletDetailsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WalletTransactionsResult> getWalletTransactions({
    required int accountId,
    String? type,
    String? startDate,
    int page = 1,
    int limit = 50,
  }) {
    return remoteDataSource.getWalletTransactions(
      accountId: accountId,
      type: type,
      startDate: startDate,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<SangamAccount> updateAccount({
    required int id,
    required String name,
    String? description,
    bool? isActive,
  }) {
    return remoteDataSource.updateAccount(
      id: id,
      name: name,
      description: description,
      isActive: isActive,
    );
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
  }) {
    return remoteDataSource.createTransaction(
      amount: amount,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      description: description,
      date: date,
      spentById: spentById,
      paidById: paidById,
    );
  }

  @override
  Future<List<SangamCategory>> getCategories() {
    return remoteDataSource.getCategories();
  }

  @override
  Future<List<SangamMemberRef>> getMembers() {
    return remoteDataSource.getMembers();
  }

  @override
  Future<List<SangamAccount>> getAccounts() {
    return remoteDataSource.getAccounts();
  }

  @override
  Future<SangamCategory> createCategory({
    required String name,
    required String type,
    int? accountId,
  }) {
    return remoteDataSource.createCategory(
      name: name,
      type: type,
      accountId: accountId,
    );
  }
}
