import 'package:equatable/equatable.dart';
import 'category_model.dart';

class SangamMemberRef extends Equatable {
  final int id;
  final String name;

  const SangamMemberRef({required this.id, required this.name});

  factory SangamMemberRef.fromJson(Map<String, dynamic> json) {
    return SangamMemberRef(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Member',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class MemberDistribution extends Equatable {
  final int memberId;
  final String memberName;
  final double total;

  const MemberDistribution({
    required this.memberId,
    required this.memberName,
    required this.total,
  });

  bool get isPositive => total >= 0;
  bool get isNegative => total < 0;

  factory MemberDistribution.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? memberNamesMap,
  }) {
    final id = json['memberId'] as int? ?? 0;
    final name = json['memberName'] as String? ??
        memberNamesMap?[id] ??
        'Member #$id';
    return MemberDistribution(
      memberId: id,
      memberName: name,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  MemberDistribution copyWith({
    int? memberId,
    String? memberName,
    double? total,
  }) {
    return MemberDistribution(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [memberId, memberName, total];
}

class SangamTransaction extends Equatable {
  final int id;
  final String type; // 'INCOME' or 'EXPENSE'
  final double amount;
  final String? description;
  final DateTime date;
  final int recordedById;
  final int? spentById;
  final int? paidById;
  final int? accountId;
  final int? categoryId;
  final SangamCategory? category;
  final SangamMemberRef? spentBy;
  final SangamMemberRef? paidBy;
  final SangamMemberRef? recordedBy;

  const SangamTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.recordedById,
    this.spentById,
    this.paidById,
    this.accountId,
    this.categoryId,
    this.category,
    this.spentBy,
    this.paidBy,
    this.recordedBy,
  });

  bool get isIncome => type == 'INCOME';
  bool get isExpense => type == 'EXPENSE';

  factory SangamTransaction.fromJson(Map<String, dynamic> json) {
    return SangamTransaction(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'EXPENSE',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      recordedById: json['recordedById'] as int? ?? 0,
      spentById: json['spentById'] as int?,
      paidById: json['paidById'] as int?,
      accountId: json['accountId'] as int?,
      categoryId: json['categoryId'] as int?,
      category: json['category'] != null && json['category'] is Map
          ? SangamCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      spentBy: json['spentBy'] != null && json['spentBy'] is Map
          ? SangamMemberRef.fromJson(json['spentBy'] as Map<String, dynamic>)
          : null,
      paidBy: json['paidBy'] != null && json['paidBy'] is Map
          ? SangamMemberRef.fromJson(json['paidBy'] as Map<String, dynamic>)
          : null,
      recordedBy: json['recordedBy'] != null && json['recordedBy'] is Map
          ? SangamMemberRef.fromJson(json['recordedBy'] as Map<String, dynamic>)
          : null,
    );
  }

  SangamTransaction copyWith({
    int? id,
    String? type,
    double? amount,
    String? description,
    DateTime? date,
    int? recordedById,
    int? spentById,
    int? paidById,
    int? accountId,
    int? categoryId,
    SangamCategory? category,
    SangamMemberRef? spentBy,
    SangamMemberRef? paidBy,
    SangamMemberRef? recordedBy,
  }) {
    return SangamTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      recordedById: recordedById ?? this.recordedById,
      spentById: spentById ?? this.spentById,
      paidById: paidById ?? this.paidById,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      spentBy: spentBy ?? this.spentBy,
      paidBy: paidBy ?? this.paidBy,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        description,
        date,
        recordedById,
        spentById,
        paidById,
        accountId,
        categoryId,
        category,
        spentBy,
        paidBy,
        recordedBy,
      ];
}

class WalletFilterStats extends Equatable {
  final double income;
  final double expense;
  final double balance;
  final List<MemberDistribution> paidByDistribution;

  const WalletFilterStats({
    required this.income,
    required this.expense,
    required this.balance,
    this.paidByDistribution = const [],
  });

  factory WalletFilterStats.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? memberNamesMap,
  }) {
    final rawDist = json['paidByDistribution'] as List<dynamic>? ?? [];
    return WalletFilterStats(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      paidByDistribution: rawDist
          .map((item) => MemberDistribution.fromJson(
                item as Map<String, dynamic>,
                memberNamesMap: memberNamesMap,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [income, expense, balance, paidByDistribution];
}

class WalletTransactionsResult extends Equatable {
  final List<SangamTransaction> transactions;
  final WalletFilterStats? filterStats;
  final int totalCount;

  const WalletTransactionsResult({
    required this.transactions,
    this.filterStats,
    this.totalCount = 0,
  });

  @override
  List<Object?> get props => [transactions, filterStats, totalCount];
}
