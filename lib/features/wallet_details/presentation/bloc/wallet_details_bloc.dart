import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/repositories/wallet_details_repository.dart';
import 'wallet_details_event.dart';
import 'wallet_details_state.dart';

class WalletDetailsBloc extends Bloc<WalletDetailsEvent, WalletDetailsState> {
  final WalletDetailsRepository walletDetailsRepository;

  WalletDetailsBloc({required this.walletDetailsRepository})
      : super(const WalletDetailsInitial()) {
    on<LoadWalletDetailsRequested>(_onLoadWalletDetailsRequested);
    on<FilterWalletTransactionsTypeChanged>(
        _onFilterWalletTransactionsTypeChanged);
    on<FilterWalletStartDateChanged>(_onFilterWalletStartDateChanged);
    on<UpdateWalletInfoRequested>(_onUpdateWalletInfoRequested);
    on<CreateTransactionRequested>(_onCreateTransactionRequested);
  }

  Future<void> _onLoadWalletDetailsRequested(
    LoadWalletDetailsRequested event,
    Emitter<WalletDetailsState> emit,
  ) async {
    emit(const WalletDetailsLoading());
    try {
      final result = await walletDetailsRepository.getWalletTransactions(
        accountId: event.initialAccount.id,
        type: event.type,
        startDate: event.fromDate?.toIso8601String(),
      );
      emit(WalletDetailsLoaded(
        account: event.initialAccount,
        transactions: result.transactions,
        allExpenseTransactions:
            result.transactions.where((t) => t.isExpense).toList(),
        filterStats: result.filterStats,
        selectedType: event.type ?? 'ALL',
        fromDate: event.fromDate,
      ));
    } catch (e) {
      emit(WalletDetailsError(e.toString()));
    }
  }

  Future<void> _onFilterWalletTransactionsTypeChanged(
    FilterWalletTransactionsTypeChanged event,
    Emitter<WalletDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WalletDetailsLoaded) return;

    emit(currentState.copyWith(isRefreshing: true, selectedType: event.type));
    try {
      final result = await walletDetailsRepository.getWalletTransactions(
        accountId: currentState.account.id,
        type: event.type == 'ALL' ? null : event.type,
        startDate: currentState.fromDate?.toIso8601String(),
      );

      List<SangamTransaction> expenses = currentState.allExpenseTransactions;
      if (event.type == 'EXPENSE') {
        expenses = result.transactions;
      } else if (event.type == 'ALL') {
        expenses = result.transactions.where((t) => t.isExpense).toList();
      }

      emit(currentState.copyWith(
        transactions: result.transactions,
        allExpenseTransactions: expenses,
        filterStats: result.filterStats,
        selectedType: event.type,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isRefreshing: false));
    }
  }

  Future<void> _onFilterWalletStartDateChanged(
    FilterWalletStartDateChanged event,
    Emitter<WalletDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WalletDetailsLoaded) return;

    emit(currentState.copyWith(
      isRefreshing: true,
      fromDate: event.fromDate,
      clearFromDate: event.fromDate == null,
    ));

    try {
      final result = await walletDetailsRepository.getWalletTransactions(
        accountId: currentState.account.id,
        type: currentState.selectedType == 'ALL'
            ? null
            : currentState.selectedType,
        startDate: event.fromDate?.toIso8601String(),
      );

      List<SangamTransaction> expenses = currentState.allExpenseTransactions;
      if (currentState.selectedType == 'EXPENSE') {
        expenses = result.transactions;
      } else if (currentState.selectedType == 'ALL') {
        expenses = result.transactions.where((t) => t.isExpense).toList();
      }

      emit(currentState.copyWith(
        transactions: result.transactions,
        allExpenseTransactions: expenses,
        filterStats: result.filterStats,
        fromDate: event.fromDate,
        clearFromDate: event.fromDate == null,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isRefreshing: false));
    }
  }

  Future<void> _onUpdateWalletInfoRequested(
    UpdateWalletInfoRequested event,
    Emitter<WalletDetailsState> emit,
  ) async {
    try {
      final updatedAccount = await walletDetailsRepository.updateAccount(
        id: event.id,
        name: event.name,
        description: event.description,
        isActive: event.isActive,
      );
      emit(WalletDetailsUpdateSuccess(updatedAccount));

      final currentState = state;
      if (currentState is WalletDetailsLoaded) {
        emit(currentState.copyWith(account: updatedAccount));
      }
    } catch (e) {
      emit(WalletDetailsError(e.toString()));
    }
  }

  Future<void> _onCreateTransactionRequested(
    CreateTransactionRequested event,
    Emitter<WalletDetailsState> emit,
  ) async {
    final currentState = state;
    final currentAccount =
        currentState is WalletDetailsLoaded ? currentState.account : null;
    final currentType =
        currentState is WalletDetailsLoaded ? currentState.selectedType : 'ALL';
    final currentFromDate =
        currentState is WalletDetailsLoaded ? currentState.fromDate : null;

    try {
      final transaction = await walletDetailsRepository.createTransaction(
        amount: event.amount,
        type: event.type,
        accountId: event.accountId,
        categoryId: event.categoryId,
        description: event.description,
        date: event.date,
        spentById: event.spentById,
        paidById: event.paidById,
      );

      emit(TransactionCreateSuccess(transaction));

      // Reload latest account balance and transactions
      if (currentAccount != null) {
        final accounts = await walletDetailsRepository.getAccounts();
        final updatedAccount = accounts.firstWhere(
          (a) => a.id == currentAccount.id,
          orElse: () => currentAccount.copyWith(
            balance: event.type == 'EXPENSE'
                ? currentAccount.balance - event.amount
                : currentAccount.balance + event.amount,
          ),
        );

        final result = await walletDetailsRepository.getWalletTransactions(
          accountId: updatedAccount.id,
          type: currentType == 'ALL' ? null : currentType,
          startDate: currentFromDate?.toIso8601String(),
        );

        emit(WalletDetailsLoaded(
          account: updatedAccount,
          transactions: result.transactions,
          allExpenseTransactions:
              result.transactions.where((t) => t.isExpense).toList(),
          filterStats: result.filterStats,
          selectedType: currentType,
          fromDate: currentFromDate,
        ));
      }
    } catch (e) {
      emit(WalletDetailsError(e.toString()));
    }
  }
}
