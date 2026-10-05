import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchDashboardRequested extends DashboardEvent {
  const FetchDashboardRequested();
}

class RefreshDashboardRequested extends DashboardEvent {
  const RefreshDashboardRequested();
}

class CreateWalletRequested extends DashboardEvent {
  final String name;
  final String? description;
  final double initialBalance;

  const CreateWalletRequested({
    required this.name,
    this.description,
    this.initialBalance = 0.0,
  });

  @override
  List<Object?> get props => [name, description, initialBalance];
}
