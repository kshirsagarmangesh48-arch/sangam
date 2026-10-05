import 'package:dio/dio.dart';
import 'package:expenses/core/constants/api_endpoints.dart';
import 'package:expenses/core/network/cache_interceptor.dart';
import 'package:expenses/core/network/response_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponseCacheManager Tests', () {
    late ResponseCacheManager cacheManager;

    setUp(() {
      cacheManager = ResponseCacheManager();
    });

    test('shouldCache returns true for valid data GET endpoints and false for others', () {
      final validGet = RequestOptions(
        path: ApiEndpoints.categories,
        method: 'GET',
      );
      expect(cacheManager.shouldCache(validGet), isTrue);

      final validAccounts = RequestOptions(
        path: ApiEndpoints.accounts,
        method: 'GET',
      );
      expect(cacheManager.shouldCache(validAccounts), isTrue);

      final postMethod = RequestOptions(
        path: ApiEndpoints.categories,
        method: 'POST',
      );
      expect(cacheManager.shouldCache(postMethod), isFalse);

      final authGet = RequestOptions(
        path: ApiEndpoints.login,
        method: 'GET',
      );
      expect(cacheManager.shouldCache(authGet), isFalse);
    });

    test('Stores and retrieves cached response within TTL', () async {
      final options = RequestOptions(
        path: ApiEndpoints.categories,
        method: 'GET',
      );
      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'categories': ['Food', 'Rent']},
      );

      await cacheManager.put(response);

      final cached = cacheManager.get(options);
      expect(cached, isNotNull);
      expect(cached!.statusCode, equals(200));
      expect(cached.data, equals({'categories': ['Food', 'Rent']}));
      expect(cached.headers.value('x-from-cache'), equals('true'));
    });

    test('Invalidates transaction and account caches when mutation occurs', () async {
      final txOptions = RequestOptions(
        path: ApiEndpoints.transactions,
        method: 'GET',
      );
      final accOptions = RequestOptions(
        path: ApiEndpoints.accounts,
        method: 'GET',
      );

      await cacheManager.put(Response(requestOptions: txOptions, data: 'txs', statusCode: 200));
      await cacheManager.put(Response(requestOptions: accOptions, data: 'accs', statusCode: 200));

      expect(cacheManager.get(txOptions), isNotNull);
      expect(cacheManager.get(accOptions), isNotNull);

      // Simulate POST /sangam-home/transactions
      final mutation = RequestOptions(
        path: ApiEndpoints.transactions,
        method: 'POST',
      );
      await cacheManager.handleMutation(mutation);

      expect(cacheManager.get(txOptions), isNull);
      expect(cacheManager.get(accOptions), isNull);
    });

    test('clearAll clears everything from cache', () async {
      final catOptions = RequestOptions(
        path: ApiEndpoints.categories,
        method: 'GET',
      );
      await cacheManager.put(Response(requestOptions: catOptions, data: 'cats', statusCode: 200));
      expect(cacheManager.get(catOptions), isNotNull);

      await cacheManager.clearAll();
      expect(cacheManager.get(catOptions), isNull);
    });
  });

  group('CacheInterceptor Dio Tests', () {
    late Dio dio;
    late ResponseCacheManager cacheManager;

    setUp(() {
      cacheManager = ResponseCacheManager();
      dio = Dio(BaseOptions(baseUrl: 'https://test.api'));
      dio.interceptors.add(CacheInterceptor(cacheManager: cacheManager));
    });

    test('Resolves directly from cache on repeated GET request', () async {
      // Seed cache
      final options = RequestOptions(
        path: '${ApiEndpoints.categories}?type=EXPENSE',
        method: 'GET',
      );
      await cacheManager.put(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'data': []},
      ));

      // Fetch with interceptor: should resolve without real network call
      final res = await dio.get('${ApiEndpoints.categories}?type=EXPENSE');
      expect(res.statusCode, equals(200));
      expect(res.headers.value('x-from-cache'), equals('true'));
    });

    test('Bypasses cache when forceRefresh / refresh is set to true in extra', () async {
      final options = RequestOptions(
        path: ApiEndpoints.categories,
        method: 'GET',
      );
      await cacheManager.put(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'seeded': true},
      ));

      // When extra['refresh'] = true, it tries to hit network (which throws in test without adapter)
      expect(
        () => dio.get(
          ApiEndpoints.categories,
          options: Options(extra: {'refresh': true}),
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('Bypasses cache and never checks or stores cache when noCache is true (Home page)', () async {
      final options = RequestOptions(
        path: ApiEndpoints.accounts,
        method: 'GET',
        extra: {'noCache': true},
      );

      expect(cacheManager.shouldCache(options), isFalse);

      // Even if cache was seeded for accounts
      await cacheManager.put(Response(
        requestOptions: RequestOptions(path: ApiEndpoints.accounts, method: 'GET'),
        statusCode: 200,
        data: {'seeded': true},
      ));

      // With noCache: true in options, dio.get bypasses cache and attempts real network
      expect(
        () => dio.get(
          ApiEndpoints.accounts,
          options: Options(extra: {'noCache': true}),
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}

