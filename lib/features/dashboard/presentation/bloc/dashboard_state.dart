import 'package:equatable/equatable.dart';
import '../../data/models/account_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<SangamAccount> accounts;
  final bool isRefreshing;

  const DashboardLoaded({
    required this.accounts,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [accounts, isRefreshing];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class DashboardWalletCreated extends DashboardState {
  final SangamAccount account;

  const DashboardWalletCreated(this.account);

  @override
  List<Object?> get props => [account];
}
