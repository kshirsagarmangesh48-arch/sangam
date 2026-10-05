import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'cache_interceptor.dart';
import 'response_cache_manager.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storageService;
  final OnUnauthorizedCallback? onUnauthorized;
  final ResponseCacheManager cacheManager;

  ApiClient({
    required this.storageService,
    this.onUnauthorized,
    String? baseUrl,
    ResponseCacheManager? cacheManager,
  }) : cacheManager = cacheManager ?? ResponseCacheManager() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.activeBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        storageService: storageService,
        dio: dio,
        onUnauthorized: onUnauthorized,
      ),
      CacheInterceptor(
        cacheManager: this.cacheManager,
      ),
    ]);
  }
}
