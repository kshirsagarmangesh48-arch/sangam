import 'package:equatable/equatable.dart';

class SangamAccount extends Equatable {
  final int id;
  final String name;
  final String? description;
  final double balance;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SangamAccount({
    required this.id,
    required this.name,
    this.description,
    required this.balance,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPositive => balance >= 0;
  bool get isNegative => balance < 0;

  factory SangamAccount.fromJson(Map<String, dynamic> json) {
    return SangamAccount(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Wallet',
      description: json['description'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'balance': balance,
        'isActive': isActive,
      };

  SangamAccount copyWith({
    int? id,
    String? name,
    String? description,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SangamAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        balance,
        isActive,
        createdAt,
        updatedAt,
      ];
}
