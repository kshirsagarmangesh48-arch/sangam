import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/auth/domain/entities/user_entity.dart';
import 'package:expenses/features/dashboard/data/models/account_model.dart';
import 'package:expenses/features/wallet_details/data/models/category_model.dart';
import 'package:expenses/features/wallet_details/data/models/transaction_model.dart';
import 'package:expenses/features/wallet_details/domain/repositories/wallet_details_repository.dart';
import 'package:expenses/features/wallet_details/presentation/bloc/wallet_details_bloc.dart';
import 'package:expenses/features/wallet_details/presentation/widgets/add_transaction_dialog.dart';

class MockWalletDetailsRepository implements WalletDetailsRepository {
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
    return SangamTransaction(
      id: 99,
      type: type,
      amount: amount,
      date: date ?? DateTime.now(),
      recordedById: 1,
      accountId: accountId,
    );
  }

  @override
  Future<List<SangamCategory>> getCategories() async {
    return const [
      SangamCategory(id: 1, name: 'Groceries', type: 'EXPENSE', accountId: null),
      SangamCategory(id: 2, name: 'Salary', type: 'INCOME', accountId: null),
      SangamCategory(id: 3, name: 'Other Wallet Fee', type: 'EXPENSE', accountId: 999),
    ];
  }

  @override
  Future<List<SangamMemberRef>> getMembers() async {
    return const [
      SangamMemberRef(id: 1, name: 'Mangesh'),
      SangamMemberRef(id: 2, name: 'Ganesh'),
    ];
  }

  @override
  Future<List<SangamAccount>> getAccounts() async {
    return const [
      SangamAccount(id: 1, name: 'Cash In Hand', balance: 5000),
    ];
  }

  @override
  Future<SangamCategory> createCategory({
    required String name,
    required String type,
    int? accountId,
  }) async {
    return SangamCategory(
      id: 100,
      name: name,
      type: type,
      accountId: accountId,
    );
  }
}

void main() {
  testWidgets('AddTransactionDialog displays form controls and validates amount',
      (tester) async {
    final mockRepo = MockWalletDetailsRepository();
    final bloc = WalletDetailsBloc(walletDetailsRepository: mockRepo);

    const testAccount = SangamAccount(id: 1, name: 'Main Wallet', balance: 1000);
    const testUser = SangamUserEntity(
      id: 1,
      name: 'Mangesh',
      email: 'mangesh@example.com',
      role: 'ADMIN',
      isActive: true,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WalletDetailsRepository>.value(value: mockRepo),
        ],
        child: BlocProvider<WalletDetailsBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AddTransactionDialog(
                account: testAccount,
                user: testUser,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Account name
    expect(find.text('Add Transaction'), findsNWidgets(2)); // Title and submit button
    expect(find.text('Main Wallet'), findsOneWidget);

    // Verify Expense and Income segments
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Verify Amount label and initial categories loaded
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Other Wallet Fee'), findsNothing); // Filtered out because accountId != 1

    // Attempt submitting without amount
    final submitButton = find.widgetWithText(ElevatedButton, 'Add Transaction');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter amount'), findsOneWidget);

    // Enter valid amount
    await tester.enterText(find.byType(TextFormField).first, '750');
    await tester.pumpAndSettle();

    // Submit valid amount
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    bloc.close();
  });
}
