import 'package:equatable/equatable.dart';
import '../../../dashboard/data/models/account_model.dart';

abstract class WalletDetailsEvent extends Equatable {
  const WalletDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadWalletDetailsRequested extends WalletDetailsEvent {
  final SangamAccount initialAccount;
  final String? type;
  final DateTime? fromDate;

  const LoadWalletDetailsRequested({
    required this.initialAccount,
    this.type,
    this.fromDate,
  });

  @override
  List<Object?> get props => [initialAccount, type, fromDate];
}

class FilterWalletTransactionsTypeChanged extends WalletDetailsEvent {
  final String type; // 'ALL', 'INCOME', 'EXPENSE'

  const FilterWalletTransactionsTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class FilterWalletStartDateChanged extends WalletDetailsEvent {
  final DateTime? fromDate;

  const FilterWalletStartDateChanged(this.fromDate);

  @override
  List<Object?> get props => [fromDate];
}

class UpdateWalletInfoRequested extends WalletDetailsEvent {
  final int id;
  final String name;
  final String? description;
  final bool? isActive;

  const UpdateWalletInfoRequested({
    required this.id,
    required this.name,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, isActive];
}

class CreateTransactionRequested extends WalletDetailsEvent {
  final double amount;
  final String type; // 'INCOME' or 'EXPENSE'
  final int accountId;
  final int? categoryId;
  final String? description;
  final DateTime? date;
  final int? spentById;
  final int? paidById;

  const CreateTransactionRequested({
    required this.amount,
    required this.type,
    required this.accountId,
    this.categoryId,
    this.description,
    this.date,
    this.spentById,
    this.paidById,
  });

  @override
  List<Object?> get props => [
        amount,
        type,
        accountId,
        categoryId,
        description,
        date,
        spentById,
        paidById,
      ];
}
