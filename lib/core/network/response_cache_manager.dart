import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class CachedEntry {
  final dynamic data;
  final int statusCode;
  final DateTime cachedAt;
  final Duration ttl;

  CachedEntry({
    required this.data,
    required this.statusCode,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'statusCode': statusCode,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'ttlMs': ttl.inMilliseconds,
    };
  }

  factory CachedEntry.fromJson(Map<String, dynamic> json) {
    return CachedEntry(
      data: json['data'],
      statusCode: json['statusCode'] as int? ?? 200,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      ttl: Duration(milliseconds: json['ttlMs'] as int? ?? 300000),
    );
  }
}

class ResponseCacheManager {
  static const String keyPrefix = 'api_cache_';
  final SharedPreferences? prefs;
  final Map<String, CachedEntry> _memoryCache = {};

  ResponseCacheManager({this.prefs});

  /// Default TTL values per endpoint
  Duration getTtlForPath(String path) {
    if (path.contains(ApiEndpoints.categories)) {
      return const Duration(minutes: 30);
    }
    if (path.contains(ApiEndpoints.members)) {
      return const Duration(minutes: 30);
    }
    if (path.contains(ApiEndpoints.accounts)) {
      return const Duration(minutes: 5);
    }
    if (path.contains(ApiEndpoints.stats)) {
      return const Duration(minutes: 5);
    }
    if (path.contains(ApiEndpoints.transactions)) {
      return const Duration(minutes: 3);
    }
    if (path.contains(ApiEndpoints.documents)) {
      return const Duration(days: 7); // Cache documents heavily until manual refresh
    }
    if (path.contains(ApiEndpoints.documentCategories)) {
      return const Duration(days: 7);
    }
    return const Duration(minutes: 5);
  }

  /// Determines if an endpoint path should be cached
  bool shouldCache(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;

    // Explicit opt-out flag (e.g. home page / live screens)
    if (options.extra['noCache'] == true ||
        options.extra['skipCache'] == true ||
        options.extra['refresh'] == true ||
        options.extra['forceRefresh'] == true) {
      return false;
    }

    final path = options.path;
    // Never cache auth endpoints
    if (path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refresh) ||
        path.contains(ApiEndpoints.changePassword)) {
      return false;
    }

    // Only cache known data endpoints
    return path.contains(ApiEndpoints.categories) ||
        path.contains(ApiEndpoints.members) ||
        path.contains(ApiEndpoints.accounts) ||
        path.contains(ApiEndpoints.stats) ||
        path.contains(ApiEndpoints.transactions) ||
        path.contains(ApiEndpoints.documents) ||
        path.contains(ApiEndpoints.documentCategories);
  }

  /// Generates a unique, normalized cache key based on path and query parameters
  String generateCacheKey(RequestOptions options) {
    final uri = options.uri;
    final sortedParams = uri.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryString = sortedParams.map((e) => '${e.key}=${e.value}').join('&');
    return '$keyPrefix${uri.path}?$queryString';
  }

  /// Retrieves a cached response if valid and not expired.
  /// If [allowExpired] is true, returns even if expired (used for offline fallback).
  Response<dynamic>? get(RequestOptions options, {bool allowExpired = false}) {
    final key = generateCacheKey(options);

    // 1. Check in-memory L1 cache
    CachedEntry? entry = _memoryCache[key];

    // 2. Check persistent L2 storage if not in memory
    if (entry == null && prefs != null) {
      final raw = prefs!.getString(key);
      if (raw != null) {
        try {
          final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
          entry = CachedEntry.fromJson(jsonMap);
          _memoryCache[key] = entry; // Hydrate memory cache
        } catch (_) {
          prefs!.remove(key);
        }
      }
    }

    if (entry == null) return null;

    if (!allowExpired && entry.isExpired) {
      return null;
    }

    return Response<dynamic>(
      requestOptions: options,
      data: entry.data,
      statusCode: entry.statusCode,
      headers: Headers.fromMap({
        'x-from-cache': ['true'],
        'x-cached-at': [entry.cachedAt.toIso8601String()],
      }),
    );
  }

  /// Saves response to both L1 in-memory and L2 persistent storage
  Future<void> put(Response<dynamic> response) async {
    final options = response.requestOptions;
    if (!shouldCache(options)) return;
    if (response.statusCode != 200) return;

    final key = generateCacheKey(options);
    final ttl = getTtlForPath(options.path);

    final entry = CachedEntry(
      data: response.data,
      statusCode: response.statusCode ?? 200,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );

    _memoryCache[key] = entry;

    if (prefs != null) {
      try {
        final serialized = jsonEncode(entry.toJson());
        await prefs!.setString(key, serialized);
      } catch (_) {
        // Ignored if data cannot be JSON encoded
      }
    }
  }

  /// Automatically invalidates relevant caches on mutations (POST, PUT, PATCH, DELETE)
  Future<void> handleMutation(RequestOptions options) async {
    final method = options.method.toUpperCase();
    if (method == 'GET') return;

    final path = options.path;

    if (path.contains(ApiEndpoints.transactions)) {
      await invalidatePattern(ApiEndpoints.transactions);
      await invalidatePattern(ApiEndpoints.accounts);
      await invalidatePattern(ApiEndpoints.stats);
    } else if (path.contains(ApiEndpoints.categories)) {
      await invalidatePattern(ApiEndpoints.categories);
    } else if (path.contains(ApiEndpoints.accounts)) {
      await invalidatePattern(ApiEndpoints.accounts);
      await invalidatePattern(ApiEndpoints.stats);
    } else if (path.contains(ApiEndpoints.members)) {
      await invalidatePattern(ApiEndpoints.members);
    } else if (path.contains(ApiEndpoints.documents)) {
      await invalidatePattern(ApiEndpoints.documents);
    } else if (path.contains(ApiEndpoints.documentCategories)) {
      await invalidatePattern(ApiEndpoints.documentCategories);
    }
  }

  /// Invalidates all cached entries matching a path pattern
  Future<void> invalidatePattern(String pattern) async {
    _memoryCache.removeWhere((key, _) => key.contains(pattern));

    if (prefs != null) {
      final keys = prefs!.getKeys().where((k) => k.startsWith(keyPrefix) && k.contains(pattern)).toList();
      for (final k in keys) {
        await prefs!.remove(k);
      }
    }
  }

  /// Clears the entire response cache (e.g. on logout)
  Future<void> clearAll() async {
    _memoryCache.clear();
    if (prefs != null) {
      final keys = prefs!.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
      for (final k in keys) {
        await prefs!.remove(k);
      }
    }
  }
}
