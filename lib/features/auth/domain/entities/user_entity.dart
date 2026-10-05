import 'package:equatable/equatable.dart';

class SangamUserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role; // 'ADMIN' or 'MEMBER'
  final String? mobile;
  final bool isActive;

  const SangamUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mobile,
    this.isActive = true,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isMember => role.toUpperCase() == 'MEMBER';

  @override
  List<Object?> get props => [id, name, email, role, mobile, isActive];
}
