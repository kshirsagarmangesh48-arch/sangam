import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/wallet_details/data/models/category_model.dart';
import 'package:expenses/features/wallet_details/data/models/transaction_model.dart';
import 'package:expenses/features/wallet_details/presentation/widgets/category_pie_chart_card.dart';

void main() {
  Widget createTestWidget(List<SangamTransaction> transactions) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryExpensePieChartCard(transactions: transactions),
        ),
      ),
    );
  }

  testWidgets('renders empty state when no expenses exist', (tester) async {
    await tester.pumpWidget(createTestWidget([]));
    await tester.pumpAndSettle();

    expect(find.text('Category Spending'), findsOneWidget);
    expect(find.text('No category expense data'), findsOneWidget);
  });

  testWidgets('renders categories, total spent, and donut chart when expenses exist',
      (tester) async {
    final transactions = [
      SangamTransaction(
        id: 1,
        type: 'EXPENSE',
        amount: 3000,
        date: DateTime.now(),
        recordedById: 1,
        category: const SangamCategory(id: 1, name: 'Groceries', type: 'EXPENSE'),
      ),
      SangamTransaction(
        id: 2,
        type: 'EXPENSE',
        amount: 1000,
        date: DateTime.now(),
        recordedById: 1,
        category: const SangamCategory(id: 2, name: 'Utilities', type: 'EXPENSE'),
      ),
      SangamTransaction(
        id: 3,
        type: 'INCOME',
        amount: 15000,
        date: DateTime.now(),
        recordedById: 1,
      ),
    ];

    await tester.pumpWidget(createTestWidget(transactions));
    await tester.pumpAndSettle();

    expect(find.text('Category Spending'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Utilities'), findsWidgets);
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);

    // Tapping on 'Utilities' selects it
    await tester.tap(find.text('Utilities').first);
    await tester.pumpAndSettle();

    expect(find.text('25.0%'), findsWidgets);
  });
}
