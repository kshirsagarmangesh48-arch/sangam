import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sangam_expense/features/expenses/data/expense_repository.dart';

// Events
abstract class ExpenseEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchDashboardData extends ExpenseEvent {
  final Map<String, dynamic>? filters;
  FetchDashboardData({this.filters});
  @override
  List<Object> get props => [filters ?? {}];
}

class FetchTransactionsRequested extends ExpenseEvent {
  final Map<String, dynamic> filters;
  FetchTransactionsRequested(this.filters);
  @override
  List<Object> get props => [filters];
}

class LoadMoreTransactions extends ExpenseEvent {
  final Map<String, dynamic> filters;
  LoadMoreTransactions(this.filters);
  @override
  List<Object> get props => [filters];
}

class AddTransactionRequested extends ExpenseEvent {
  final Map<String, dynamic> data;
  AddTransactionRequested(this.data);
  @override
  List<Object> get props => [data];
}

class DeleteTransactionRequested extends ExpenseEvent {
  final int id;
  DeleteTransactionRequested(this.id);
  @override
  List<Object> get props => [id];
}

class UpdateTransactionRequested extends ExpenseEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateTransactionRequested(this.id, this.data);
  @override
  List<Object> get props => [id, data];
}

class CreateWalletRequested extends ExpenseEvent {
  final String name;
  final String description;
  CreateWalletRequested(this.name, this.description);
  @override
  List<Object> get props => [name, description];
}

class UpdateWalletRequested extends ExpenseEvent {
  final int id;
  final String name;
  final String description;
  UpdateWalletRequested(this.id, this.name, this.description);
  @override
  List<Object> get props => [id, name, description];
}

class CreateCategoryRequested extends ExpenseEvent {
  final String name;
  final String type;
  final int? accountId;
  CreateCategoryRequested(this.name, this.type, {this.accountId});
  @override
  List<Object> get props => [name, type, accountId ?? -1];
}

class UpdateCategoryRequested extends ExpenseEvent {
  final int id;
  final String name;
  final String type;
  final bool isActive;
  final int? accountId;
  UpdateCategoryRequested(this.id, this.name, this.type, this.isActive, {this.accountId});
  @override
  List<Object> get props => [id, name, type, isActive, accountId ?? -1];
}

class DeleteCategoryRequested extends ExpenseEvent {
  final int id;
  DeleteCategoryRequested(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class ExpenseState extends Equatable {
  @override
  List<Object> get props => [];
}

class ExpenseInitial extends ExpenseState {}
class ExpenseLoading extends ExpenseState {}
class ExpenseDashboardLoaded extends ExpenseState {
  final Map<String, dynamic> stats;
  final List<dynamic> transactions;
  final List<dynamic> accounts;
  final List<dynamic> categories;
  final List<dynamic> familyMembers;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? filterStats;
  final bool isRefreshingTransactions;
  final bool isLoadingMore;

  ExpenseDashboardLoaded({
    required this.stats,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.familyMembers,
    this.pagination,
    this.filterStats,
    this.isRefreshingTransactions = false,
    this.isLoadingMore = false,
  });

  ExpenseDashboardLoaded copyWith({
    Map<String, dynamic>? stats,
    List<dynamic>? transactions,
    List<dynamic>? accounts,
    List<dynamic>? categories,
    List<dynamic>? familyMembers,
    Map<String, dynamic>? pagination,
    Map<String, dynamic>? filterStats,
    bool? isRefreshingTransactions,
    bool? isLoadingMore,
  }) {
    return ExpenseDashboardLoaded(
      stats: stats ?? this.stats,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      familyMembers: familyMembers ?? this.familyMembers,
      pagination: pagination ?? this.pagination,
      filterStats: filterStats ?? this.filterStats,
      isRefreshingTransactions: isRefreshingTransactions ?? this.isRefreshingTransactions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [
        stats,
        transactions,
        accounts,
        categories,
        familyMembers,
        pagination ?? {},
        filterStats ?? {},
        isRefreshingTransactions,
        isLoadingMore
      ];
}
class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
  @override
  List<Object> get props => [message];
}

class ExpenseSuccess extends ExpenseState {
  final String message;
  ExpenseSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository repository;

  ExpenseBloc(this.repository) : super(ExpenseInitial()) {
    on<FetchDashboardData>((event, emit) async {
      if (state is! ExpenseDashboardLoaded) {
        emit(ExpenseLoading());
      }
      try {
        final results = await Future.wait([
          repository.getStats(event.filters),
          repository.getTransactions(event.filters),
          repository.getAccounts(),
          repository.getCategories(),
          repository.getFamilyMembers(),
        ]);

        emit(ExpenseDashboardLoaded(
          stats: (results[0] as Map<String, dynamic>)['data'],
          transactions: (results[1] as Map<String, dynamic>)['data'],
          accounts: results[2] as List<dynamic>,
          categories: results[3] as List<dynamic>,
          familyMembers: results[4] as List<dynamic>,
          pagination: (results[1] as Map<String, dynamic>)['pagination'],
          filterStats: (results[1] as Map<String, dynamic>)['filterStats'],
        ));
      } catch (e) {
        emit(ExpenseError(e.toString()));
      }
    });

    on<FetchTransactionsRequested>((event, emit) async {
      if (state is ExpenseDashboardLoaded) {
        final current = state as ExpenseDashboardLoaded;
        // Clear transactions and reset stats while refreshing to avoid showing stale data
        emit(current.copyWith(
          isRefreshingTransactions: true,
          transactions: [],
          stats: {
            'totalIncome': 0.0,
            'totalExpense': 0.0,
            'netBalance': 0.0,
            'paidByDistribution': [],
          },
          filterStats: {
            'paidByDistribution': [],
          },
        ));
        try {
          final result = await repository.getTransactions(event.filters);
          emit(current.copyWith(
            transactions: result['data'],
            pagination: result['pagination'],
            filterStats: result['filterStats'],
            isRefreshingTransactions: false,
          ));
        } catch (e) {
          emit(current.copyWith(isRefreshingTransactions: false));
          emit(ExpenseError(e.toString()));
          emit(current.copyWith(isRefreshingTransactions: false));
        }
      }
    });

    on<LoadMoreTransactions>((event, emit) async {
      if (state is ExpenseDashboardLoaded) {
        final current = state as ExpenseDashboardLoaded;
        emit(current.copyWith(isLoadingMore: true));
        try {
          final result = await repository.getTransactions(event.filters);
          emit(current.copyWith(
            transactions: [...current.transactions, ...result['data']],
            pagination: result['pagination'],
            filterStats: result['filterStats'],
            isLoadingMore: false,
          ));
        } catch (e) {
          emit(current.copyWith(isLoadingMore: false));
        }
      }
    });

    on<AddTransactionRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.addTransaction(event.data);
        emit(ExpenseSuccess("Transaction added successfully"));
        if (current != null) emit(current);
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<DeleteTransactionRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.deleteTransaction(event.id);
        emit(ExpenseSuccess("Transaction deleted successfully"));
        if (current != null) emit(current);
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<UpdateTransactionRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.updateTransaction(event.id, event.data);
        emit(ExpenseSuccess("Transaction updated successfully"));
        if (current != null) emit(current);
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<CreateWalletRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.createAccount(event.name, event.description);
        emit(ExpenseSuccess("Wallet created successfully"));
        if (current != null) emit(current);
        add(FetchDashboardData()); // Refresh dashboard
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });
    on<UpdateWalletRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.updateAccount(event.id, event.name, event.description);
        emit(ExpenseSuccess("Wallet updated successfully"));
        if (current != null) emit(current);
        add(FetchDashboardData()); // Refresh dashboard
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<CreateCategoryRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.createCategory(event.name, event.type, accountId: event.accountId);
        emit(ExpenseSuccess("Category created successfully"));
        if (current != null) emit(current);
        add(FetchDashboardData()); // Refresh dashboard
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<UpdateCategoryRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.updateCategory(event.id, event.name, event.type, event.isActive, accountId: event.accountId);
        emit(ExpenseSuccess("Category updated successfully"));
        if (current != null) emit(current);
        add(FetchDashboardData()); // Refresh dashboard
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });

    on<DeleteCategoryRequested>((event, emit) async {
      final current = state is ExpenseDashboardLoaded ? state as ExpenseDashboardLoaded : null;
      try {
        await repository.deleteCategory(event.id);
        emit(ExpenseSuccess("Category deleted successfully"));
        if (current != null) emit(current);
        add(FetchDashboardData()); // Refresh dashboard
      } catch (e) {
        emit(ExpenseError(e.toString()));
        if (current != null) emit(current);
      }
    });
  }
}
