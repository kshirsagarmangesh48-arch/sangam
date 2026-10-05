import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberEmail;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberEmail = true,
  });

  @override
  List<Object?> get props => [email, password, rememberEmail];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const AuthChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
