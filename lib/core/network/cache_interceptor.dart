import 'package:dio/dio.dart';
import 'response_cache_manager.dart';

class CacheInterceptor extends Interceptor {
  final ResponseCacheManager cacheManager;

  CacheInterceptor({required this.cacheManager});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Check if caller requested no-cache or force refresh (e.g. home page, pull-to-refresh)
    final noCache = options.extra['noCache'] == true ||
        options.extra['skipCache'] == true ||
        options.extra['refresh'] == true ||
        options.extra['forceRefresh'] == true;

    if (!noCache && cacheManager.shouldCache(options)) {
      final cachedResponse = cacheManager.get(options);
      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final method = response.requestOptions.method.toUpperCase();
    final noCache = response.requestOptions.extra['noCache'] == true ||
        response.requestOptions.extra['skipCache'] == true;

    if (method == 'GET') {
      if (!noCache && cacheManager.shouldCache(response.requestOptions)) {
        cacheManager.put(response);
      }
    } else {
      // Invalidate relevant cache entries on any successful mutation
      cacheManager.handleMutation(response.requestOptions);
    }

    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final options = err.requestOptions;
    final noCache = options.extra['noCache'] == true ||
        options.extra['skipCache'] == true ||
        options.extra['refresh'] == true ||
        options.extra['forceRefresh'] == true;

    // For GET requests where network is unreachable or timed out, attempt offline cache fallback
    if (!noCache &&
        options.method.toUpperCase() == 'GET' &&
        cacheManager.shouldCache(options)) {
      final isNetworkOrTimeout = err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          (err.response != null && err.response!.statusCode != null && err.response!.statusCode! >= 500);

      if (isNetworkOrTimeout) {
        final fallbackResponse = cacheManager.get(options, allowExpired: true);
        if (fallbackResponse != null) {
          fallbackResponse.headers.add('x-from-cache-fallback', 'true');
          return handler.resolve(fallbackResponse);
        }
      }
    }

    return handler.next(err);
  }
}
