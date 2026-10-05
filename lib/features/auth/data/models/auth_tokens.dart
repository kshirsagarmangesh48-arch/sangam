import 'package:equatable/equatable.dart';
import 'user_model.dart';

class AuthTokens extends Equatable {
  final String token;
  final String refreshToken;

  const AuthTokens({
    required this.token,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken];
}

class LoginResult extends Equatable {
  final SangamUser user;
  final AuthTokens tokens;

  const LoginResult({
    required this.user,
    required this.tokens,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      user: SangamUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json),
    );
  }

  @override
  List<Object?> get props => [user, tokens];
}
