import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/auth/domain/entities/user_entity.dart';
import 'package:expenses/features/dashboard/data/models/account_model.dart';
import 'package:expenses/features/auth/domain/repositories/auth_repository.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expenses/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expenses/features/settings/presentation/screens/settings_screen.dart';
import 'package:expenses/features/settings/presentation/widgets/add_category_dialog.dart';
import 'package:expenses/features/wallet_details/data/models/category_model.dart';
import 'package:expenses/features/wallet_details/data/models/transaction_model.dart';
import 'package:expenses/features/wallet_details/domain/repositories/wallet_details_repository.dart';

class MockWalletDetailsRepo implements WalletDetailsRepository {
  bool categoryCreated = false;
  String? createdCategoryName;
  String? createdCategoryType;
  int? createdCategoryAccountId;

  @override
  Future<SangamCategory> createCategory({
    required String name,
    required String type,
    int? accountId,
  }) async {
    categoryCreated = true;
    createdCategoryName = name;
    createdCategoryType = type;
    createdCategoryAccountId = accountId;
    return SangamCategory(
      id: 50,
      name: name,
      type: type,
      accountId: accountId,
    );
  }

  @override
  Future<List<SangamAccount>> getAccounts() async {
    return const [
      SangamAccount(id: 1, name: 'Cash Bucket', balance: 2000),
      SangamAccount(id: 2, name: 'HDFC Bank', balance: 50000),
    ];
  }

  @override
  Future<List<SangamCategory>> getCategories() async => [];

  @override
  Future<List<SangamMemberRef>> getMembers() async => [];

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
    throw UnimplementedError();
  }

  @override
  Future<WalletTransactionsResult> getWalletTransactions({
    required int accountId,
    String? type,
    String? startDate,
    int page = 1,
    int limit = 50,
  }) async {
    return const WalletTransactionsResult(transactions: []);
  }

  @override
  Future<SangamAccount> updateAccount({
    required int id,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    return SangamAccount(id: id, name: name, balance: 100);
  }
}

class MockAuthRepo implements AuthRepository {
  @override
  Future<SangamUserEntity?> getCachedUser() async => null;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<String?> getRememberedEmail() async => null;

  @override
  Future<SangamUserEntity> login({
    required String email,
    required String password,
    bool rememberEmail = false,
  }) async =>
      const SangamUserEntity(
        id: 1,
        name: 'Admin',
        email: 'admin@sangam.in',
        role: 'ADMIN',
        isActive: true,
      );

  @override
  Future<void> logout() async {}

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {}
}

class MockDashboardRepo implements DashboardRepository {
  @override
  Future<List<SangamAccount>> getAccounts() async => [];

  @override
  Future<SangamAccount> createAccount({
    required String name,
    String? description,
    double balance = 0.0,
  }) async =>
      SangamAccount(id: 1, name: name, balance: balance);
}

void main() {
  testWidgets('AddCategoryDialog validates input and creates category',
      (tester) async {
    final mockRepo = MockWalletDetailsRepo();

    await tester.pumpWidget(
      RepositoryProvider<WalletDetailsRepository>.value(
        value: mockRepo,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AddCategoryDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog header
    expect(find.text('Add Category'), findsNWidgets(2)); // Title and button
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Category Name'), findsOneWidget);
    expect(find.text('Applicable Wallet'), findsOneWidget);

    // Attempt to submit empty name
    final submitButton = find.widgetWithText(ElevatedButton, 'Add Category');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter category name'), findsOneWidget);

    // Enter valid category name
    await tester.enterText(find.byType(TextFormField), 'Dining & Cafe');
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(mockRepo.categoryCreated, isTrue);
    expect(mockRepo.createdCategoryName, 'Dining & Cafe');
    expect(mockRepo.createdCategoryType, 'EXPENSE');
    expect(mockRepo.createdCategoryAccountId, isNull); // Default is global
  });

  testWidgets('SettingsScreen displays Add Category option for Admin',
      (tester) async {
    const adminUser = SangamUserEntity(
      id: 1,
      name: 'Admin User',
      email: 'admin@sangam.in',
      role: 'ADMIN',
      isActive: true,
    );

    final authBloc = AuthBloc(authRepository: MockAuthRepo());
    final dashboardBloc = DashboardBloc(dashboardRepository: MockDashboardRepo());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(user: adminUser),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Management section with Add New Wallet and Add Category
    expect(find.text('Management'), findsOneWidget);
    expect(find.text('Add New Wallet'), findsOneWidget);
    expect(find.text('Add Category'), findsOneWidget);

    authBloc.close();
    dashboardBloc.close();
  });
}
