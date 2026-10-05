import 'package:equatable/equatable.dart';

class SangamCategory extends Equatable {
  final int id;
  final String name;
  final String type; // 'INCOME' or 'EXPENSE'
  final bool isActive;
  final int? accountId;

  const SangamCategory({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
    this.accountId,
  });

  bool get isIncome => type == 'INCOME';
  bool get isExpense => type == 'EXPENSE';

  factory SangamCategory.fromJson(Map<String, dynamic> json) {
    return SangamCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'General',
      type: json['type'] as String? ?? 'EXPENSE',
      isActive: json['isActive'] as bool? ?? true,
      accountId: json['accountId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'isActive': isActive,
        'accountId': accountId,
      };

  @override
  List<Object?> get props => [id, name, type, isActive, accountId];
}
