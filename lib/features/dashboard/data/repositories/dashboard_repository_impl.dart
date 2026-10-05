import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../models/account_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SangamAccount>> getAccounts() {
    return remoteDataSource.getAccounts();
  }

  @override
  Future<SangamAccount> createAccount({
    required String name,
    String? description,
    double balance = 0.0,
  }) {
    return remoteDataSource.createAccount(
      name: name,
      description: description,
      balance: balance,
    );
  }
}
