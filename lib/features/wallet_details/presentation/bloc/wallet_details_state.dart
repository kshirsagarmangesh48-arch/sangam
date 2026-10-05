import 'package:equatable/equatable.dart';
import '../../../dashboard/data/models/account_model.dart';
import '../../data/models/transaction_model.dart';

abstract class WalletDetailsState extends Equatable {
  const WalletDetailsState();

  @override
  List<Object?> get props => [];
}

class WalletDetailsInitial extends WalletDetailsState {
  const WalletDetailsInitial();
}

class WalletDetailsLoading extends WalletDetailsState {
  const WalletDetailsLoading();
}

class WalletDetailsLoaded extends WalletDetailsState {
  final SangamAccount account;
  final List<SangamTransaction> transactions;
  final List<SangamTransaction> allExpenseTransactions;
  final WalletFilterStats? filterStats;
  final String selectedType; // 'ALL', 'INCOME', 'EXPENSE'
  final DateTime? fromDate;
  final bool isRefreshing;

  const WalletDetailsLoaded({
    required this.account,
    required this.transactions,
    this.allExpenseTransactions = const [],
    this.filterStats,
    this.selectedType = 'ALL',
    this.fromDate,
    this.isRefreshing = false,
  });

  WalletDetailsLoaded copyWith({
    SangamAccount? account,
    List<SangamTransaction>? transactions,
    List<SangamTransaction>? allExpenseTransactions,
    WalletFilterStats? filterStats,
    String? selectedType,
    DateTime? fromDate,
    bool clearFromDate = false,
    bool? isRefreshing,
  }) {
    return WalletDetailsLoaded(
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      allExpenseTransactions:
          allExpenseTransactions ?? this.allExpenseTransactions,
      filterStats: filterStats ?? this.filterStats,
      selectedType: selectedType ?? this.selectedType,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        account,
        transactions,
        allExpenseTransactions,
        filterStats,
        selectedType,
        fromDate,
        isRefreshing,
      ];
}

class WalletDetailsError extends WalletDetailsState {
  final String message;

  const WalletDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletDetailsUpdateSuccess extends WalletDetailsState {
  final SangamAccount updatedAccount;

  const WalletDetailsUpdateSuccess(this.updatedAccount);

  @override
  List<Object?> get props => [updatedAccount];
}

class TransactionCreateSuccess extends WalletDetailsState {
  final SangamTransaction transaction;

  const TransactionCreateSuccess(this.transaction);

  @override
  List<Object?> get props => [transaction];
}
