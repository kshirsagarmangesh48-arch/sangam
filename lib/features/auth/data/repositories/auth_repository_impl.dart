import '../../../../core/network/response_cache_manager.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;
  final ResponseCacheManager? cacheManager;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    this.cacheManager,
  });

  @override
  Future<SangamUserEntity> login({
    required String email,
    required String password,
    bool rememberEmail = true,
  }) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );

    // Save tokens and user details locally
    await storageService.saveTokens(
      token: result.tokens.token,
      refreshToken: result.tokens.refreshToken,
    );
    await storageService.saveUser(result.user.toJson());

    if (rememberEmail) {
      await storageService.saveRememberedEmail(email);
    }

    return _toEntity(result.user);
  }

  @override
  Future<void> logout() async {
    await storageService.clearAuthData();
    await cacheManager?.clearAll();
  }

  @override
  Future<SangamUserEntity?> getCachedUser() async {
    final map = await storageService.getUser();
    if (map == null) return null;
    return _toEntity(SangamUser.fromJson(map));
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storageService.getAccessToken();
    final refreshToken = await storageService.getRefreshToken();
    return (token != null && token.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<String?> getRememberedEmail() async {
    return await storageService.getRememberedEmail();
  }

  SangamUserEntity _toEntity(SangamUser model) {
    return SangamUserEntity(
      id: model.id,
      name: model.name,
      email: model.email,
      role: model.role,
      mobile: model.mobile,
      isActive: model.isActive,
    );
  }
}
