import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardBloc({required this.dashboardRepository})
      : super(const DashboardInitial()) {
    on<FetchDashboardRequested>(_onFetchDashboardRequested);
    on<RefreshDashboardRequested>(_onRefreshDashboardRequested);
    on<CreateWalletRequested>(_onCreateWalletRequested);
  }

  Future<void> _onFetchDashboardRequested(
    FetchDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final accounts = await dashboardRepository.getAccounts();
      emit(DashboardLoaded(accounts: accounts));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardRequested(
    RefreshDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final currentAccounts =
        state is DashboardLoaded ? (state as DashboardLoaded).accounts : null;
    if (currentAccounts != null) {
      emit(DashboardLoaded(accounts: currentAccounts, isRefreshing: true));
    }
    try {
      final accounts = await dashboardRepository.getAccounts();
      emit(DashboardLoaded(accounts: accounts, isRefreshing: false));
    } catch (e) {
      if (currentAccounts != null) {
        emit(DashboardLoaded(accounts: currentAccounts, isRefreshing: false));
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }

  Future<void> _onCreateWalletRequested(
    CreateWalletRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final newAccount = await dashboardRepository.createAccount(
        name: event.name,
        description: event.description,
        balance: event.initialBalance,
      );
      emit(DashboardWalletCreated(newAccount));
      add(const RefreshDashboardRequested());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
