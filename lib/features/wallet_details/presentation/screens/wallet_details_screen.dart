import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/core/utils/currency_formatter.dart';
import 'package:expenses/features/auth/domain/entities/user_entity.dart';
import 'package:expenses/features/dashboard/data/models/account_model.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_event.dart';
import '../bloc/wallet_details_bloc.dart';
import '../bloc/wallet_details_event.dart';
import '../bloc/wallet_details_state.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/category_pie_chart_card.dart';
import '../widgets/edit_wallet_dialog.dart';
import '../widgets/member_distribution_card.dart';
import '../widgets/wallet_transaction_tile.dart';

class WalletDetailsScreen extends StatefulWidget {
  final SangamAccount account;
  final SangamUserEntity user;

  const WalletDetailsScreen({
    super.key,
    required this.account,
    required this.user,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<WalletDetailsBloc>().add(
            LoadWalletDetailsRequested(initialAccount: widget.account),
          );
    });
  }

  IconData _resolveWalletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cash')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('bank') ||
        lower.contains('sbi') ||
        lower.contains('hdfc') ||
        lower.contains('icici') ||
        lower.contains('axis')) {
      return Icons.account_balance_outlined;
    }
    if (lower.contains('card') || lower.contains('credit')) {
      return Icons.credit_card_outlined;
    }
    if (lower.contains('pay') || lower.contains('upi')) {
      return Icons.qr_code_rounded;
    }
    return Icons.account_balance_wallet_outlined;
  }

  Future<void> _selectFromDate(DateTime? currentDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (!mounted || picked == null) return;
    context
        .read<WalletDetailsBloc>()
        .add(FilterWalletStartDateChanged(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    return BlocConsumer<WalletDetailsBloc, WalletDetailsState>(
      listener: (context, state) {
        if (state is WalletDetailsUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Wallet updated successfully',
                style: text.bodyMedium?.copyWith(color: colors.onPrimary),
              ),
              backgroundColor: familyTheme.success,
            ),
          );
          context.read<DashboardBloc>().add(const RefreshDashboardRequested());
        } else if (state is TransactionCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transaction recorded successfully',
                style: text.bodyMedium?.copyWith(color: colors.onPrimary),
              ),
              backgroundColor: familyTheme.success,
            ),
          );
          context.read<DashboardBloc>().add(const RefreshDashboardRequested());
        }
      },
      builder: (context, state) {
        final currentAccount = state is WalletDetailsLoaded
            ? state.account
            : widget.account;

        final isNegative = currentAccount.isNegative;
        final balanceColor = isNegative ? colors.error : familyTheme.success;
        final balanceBgColor =
            isNegative ? colors.errorContainer : familyTheme.successContainer;

        final selectedType =
            state is WalletDetailsLoaded ? state.selectedType : 'ALL';
        final fromDate =
            state is WalletDetailsLoaded ? state.fromDate : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentAccount.name),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletDetailsBloc>().add(
                    LoadWalletDetailsRequested(
                      initialAccount: currentAccount,
                      type: selectedType == 'ALL' ? null : selectedType,
                      fromDate: fromDate,
                    ),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Header Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _resolveWalletIcon(currentAccount.name),
                                  color: colors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentAccount.name,
                                      style: text.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (currentAccount.description != null &&
                                        currentAccount.description!
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        currentAccount.description!,
                                        style: text.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isNegative)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: balanceBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Deficit',
                                    style: text.bodySmall?.copyWith(
                                      color: balanceColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isNegative
                                        ? 'Current Deficit'
                                        : 'Current Balance',
                                    style: text.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(
                                        currentAccount.balance),
                                    style: text.headlineMedium?.copyWith(
                                      color: balanceColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // From Date (Wallet Opening / Active Since Date)
                              if (currentAccount.createdAt != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'From Date',
                                      style: text.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: colors.primary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(
                                                currentAccount.createdAt!),
                                            style: text.bodySmall?.copyWith(
                                              color: colors.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Member Distribution per Family Member (instead of income/spends)
                          if (state is WalletDetailsLoaded &&
                              state.filterStats != null) ...[
                            const SizedBox(height: 16),
                            MemberDistributionCard(
                              distribution:
                                  state.filterStats!.paidByDistribution,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Based Expenses Pie Chart
                  if (state is WalletDetailsLoaded) ...[
                    CategoryExpensePieChartCard(
                      transactions: state.allExpenseTransactions.isNotEmpty
                          ? state.allExpenseTransactions
                          : state.transactions,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 8),
                  ],

                  // Filter Row with Flow Types & From Date Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: text.titleLarge,
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            type: 'ALL',
                            isSelected: selectedType == 'ALL',
                          ),
                          _buildFilterChip(
                            label: 'Income',
                            type: 'INCOME',
                            isSelected: selectedType == 'INCOME',
                          ),
                          _buildFilterChip(
                            label: 'Expense',
                            type: 'EXPENSE',
                            isSelected: selectedType == 'EXPENSE',
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Filter By From Date Bar
                  Row(
                    children: [
                      ActionChip(
                        avatar: Icon(
                          Icons.date_range_outlined,
                          size: 16,
                          color: fromDate != null
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        label: Text(
                          fromDate != null
                              ? 'From: ${DateFormat('dd MMM yyyy').format(fromDate)}'
                              : 'Filter From Date',
                          style: text.bodySmall?.copyWith(
                            fontWeight: fromDate != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: fromDate != null
                                ? colors.primary
                                : colors.onSurface,
                          ),
                        ),
                        onPressed: () => _selectFromDate(fromDate),
                      ),
                      if (fromDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Clear From Date',
                          onPressed: () {
                            context
                                .read<WalletDetailsBloc>()
                                .add(const FilterWalletStartDateChanged(null));
                          },
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Transactions List Body
                  if (state is WalletDetailsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is WalletDetailsError)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: colors.error, size: 36),
                              const SizedBox(height: 8),
                              Text(state.message, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<WalletDetailsBloc>().add(
                                        LoadWalletDetailsRequested(
                                          initialAccount: currentAccount,
                                          fromDate: fromDate,
                                        ),
                                      );
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is WalletDetailsLoaded) ...[
                    if (state.transactions.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No transactions yet',
                                  style: text.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedType == 'ALL'
                                      ? (fromDate != null
                                          ? 'No transactions found from ${DateFormat('dd MMM yyyy').format(fromDate)}.'
                                          : 'Transactions linked to this wallet will appear here.')
                                      : 'No $selectedType transactions recorded for this wallet.',
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.transactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return WalletTransactionTile(
                            transaction: state.transactions[index],
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (widget.user.isAdmin) ...[
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) =>
                              EditWalletDialog(account: currentAccount),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Wallet'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddTransactionDialog(
                          account: currentAccount,
                          user: widget.user,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Transaction'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String type,
    required bool isSelected,
  }) {
    final colors = context.colors;
    final text = context.text;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: text.bodySmall?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colors.primary : colors.onSurface,
        ),
      ),
      onSelected: (_) {
        context
            .read<WalletDetailsBloc>()
            .add(FilterWalletTransactionsTypeChanged(type));
      },
    );
  }
}
