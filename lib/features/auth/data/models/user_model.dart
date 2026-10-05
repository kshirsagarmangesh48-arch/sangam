import 'package:equatable/equatable.dart';

class SangamUser extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role; // 'ADMIN' or 'MEMBER'
  final String? mobile;
  final bool isActive;

  const SangamUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mobile,
    this.isActive = true,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isMember => role.toUpperCase() == 'MEMBER';

  factory SangamUser.fromJson(Map<String, dynamic> json) {
    return SangamUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'MEMBER',
      mobile: json['mobile'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'mobile': mobile,
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [id, name, email, role, mobile, isActive];
}
