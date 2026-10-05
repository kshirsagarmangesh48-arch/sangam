import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<SangamUserEntity> login({
    required String email,
    required String password,
    bool rememberEmail = true,
  });

  Future<void> logout();

  Future<SangamUserEntity?> getCachedUser();

  Future<bool> isAuthenticated();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<String?> getRememberedEmail();
}
