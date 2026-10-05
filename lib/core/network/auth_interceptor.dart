import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storageService;
  final Dio dio;
  final OnUnauthorizedCallback? onUnauthorized;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
    this.onUnauthorized,
  });

  bool _shouldAttachAuthToken(RequestOptions options) {
    final path = options.path;

    // Skip injecting auth token for public auth endpoints
    if (path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refresh)) {
      return false;
    }

    // If it's a fully qualified URL, check whether it is targeting an external host
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      if (uri == null) return false;

      final host = uri.host.toLowerCase();

      // S3 or DigitalOcean Spaces or external CDNs MUST NOT receive Bearer token headers!
      // AWS S3 & Spaces reject requests with "Bearer" authorization with HTTP 400 Bad Request
      if (host.contains('digitaloceanspaces.com') ||
          host.contains('amazonaws.com') ||
          host.contains('cdn.')) {
        return false;
      }

      // Only attach if it targets our backend API host
      final isOurBackend = host == 'api.makeinsatara.in' ||
          host == '206.189.136.110' ||
          host == 'localhost' ||
          host == '10.0.2.2';

      if (!isOurBackend) {
        return false;
      }

      // Static asset endpoints under /uploads/ are public and don't need auth tokens
      if (uri.path.startsWith('/uploads/')) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldAttachAuthToken(options)) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Do NOT override Content-Type if it is FormData, already set, or a GET request
    if (options.data is! FormData &&
        options.method.toUpperCase() != 'GET' &&
        !options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isRefreshCall = err.requestOptions.path.contains(ApiEndpoints.refresh);

    if (response?.statusCode == 401 && !isRefreshCall) {
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Use isolated Dio instance to avoid infinite interceptor loops
          final tokenDio = Dio(
            BaseOptions(
              baseUrl: err.requestOptions.baseUrl,
              headers: {'Content-Type': 'application/json'},
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

          final refreshResponse = await tokenDio.post(
            ApiEndpoints.refresh,
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200 &&
              refreshResponse.data['success'] == true) {
            final data = refreshResponse.data['data'];
            final newToken = data['token'] as String;
            final newRefreshToken = data['refreshToken'] as String;

            // Save new rotated tokens
            await storageService.saveTokens(
              token: newToken,
              refreshToken: newRefreshToken,
            );

            // Retry original request with fresh token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed or token expired
          await storageService.clearAuthData();
          onUnauthorized?.call();
          return handler.next(err);
        }
      } else {
        // No refresh token available
        await storageService.clearAuthData();
        onUnauthorized?.call();
      }
    }

    return handler.next(err);
  }
}
