import 'package:dio/dio.dart';
import 'package:expenses/core/constants/api_endpoints.dart';
import 'package:expenses/core/network/auth_interceptor.dart';
import 'package:expenses/core/storage/secure_storage_service.dart';
import 'package:expenses/features/documents/data/models/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService implements SecureStorageService {
  String? mockToken = 'mock_jwt_access_token_123';
  String? mockRefreshToken = 'mock_refresh_token_456';

  @override
  Future<String?> getAccessToken() async => mockToken;

  @override
  Future<String?> getRefreshToken() async => mockRefreshToken;

  @override
  Future<void> saveTokens({required String token, required String refreshToken}) async {
    mockToken = token;
    mockRefreshToken = refreshToken;
  }

  @override
  Future<void> clearAuthData() async {
    mockToken = null;
    mockRefreshToken = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthInterceptor CDN & Spaces Protection Tests', () {
    late FakeSecureStorageService fakeStorage;
    late Dio dio;
    late AuthInterceptor authInterceptor;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      dio = Dio();
      authInterceptor = AuthInterceptor(
        storageService: fakeStorage,
        dio: dio,
      );
    });

    test('Does NOT inject Authorization or Content-Type headers for DigitalOcean Spaces URL', () async {
      final options = RequestOptions(
        path: 'https://sangam-toys.sgp1.cdn.digitaloceanspaces.com/uploads/sangam-home/documents/sample.pdf',
        method: 'GET',
      );

      final handler = RequestInterceptorHandler();
      await authInterceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse,
          reason: 'Spaces CDN must never receive Bearer tokens as it causes HTTP 400 Bad Request');
      expect(options.headers['Content-Type'], isNull,
          reason: 'GET request to CDN should not have application/json forced');
    });

    test('Does NOT inject Authorization for direct digitaloceanspaces.com endpoint', () async {
      final options = RequestOptions(
        path: 'https://sangam-toys.sgp1.digitaloceanspaces.com/uploads/sangam-home/documents/sample.pdf',
        method: 'GET',
      );

      final handler = RequestInterceptorHandler();
      await authInterceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('Injects Authorization token for backend API requests', () async {
      final options = RequestOptions(
        path: ApiEndpoints.documents,
        method: 'GET',
      );

      final handler = RequestInterceptorHandler();
      await authInterceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer mock_jwt_access_token_123'));
    });

    test('Does NOT inject Authorization for auth endpoints like login and refresh', () async {
      final options = RequestOptions(
        path: ApiEndpoints.login,
        method: 'POST',
      );

      final handler = RequestInterceptorHandler();
      await authInterceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ApiEndpoints and DocumentModel URL resolution', () {
    test('resolveDocumentUrl preserves fully qualified CDN and Spaces URLs', () {
      const cdnUrl = 'https://sangam-toys.sgp1.cdn.digitaloceanspaces.com/uploads/sangam-home/documents/doc.pdf';
      expect(ApiEndpoints.resolveDocumentUrl(cdnUrl), equals(cdnUrl));
    });

    test('resolveDocumentUrl formats relative paths correctly', () {
      const relativePath = 'uploads/sangam-home/documents/receipt.pdf';
      expect(ApiEndpoints.resolveDocumentUrl(relativePath), equals('https://api.makeinsatara.in/$relativePath'));
    });

    test('DocumentModel parses Spaces location and fileUrl correctly', () {
      final json = {
        'id': 'doc-123',
        'title': 'Electricity Bill',
        'fileName': 'bill.pdf',
        'fileUrl': 'https://sangam-toys.sgp1.cdn.digitaloceanspaces.com/uploads/sangam-home/documents/bill.pdf',
        'category': 'Utilities',
        'fileSizeBytes': 102400,
        'createdAt': '2026-03-01T10:00:00.000Z',
      };

      final model = DocumentModel.fromJson(json);
      expect(model.id, equals('doc-123'));
      expect(model.name, equals('Electricity Bill'));
      expect(model.fileUrl, equals('https://sangam-toys.sgp1.cdn.digitaloceanspaces.com/uploads/sangam-home/documents/bill.pdf'));
      expect(model.isPdf, isTrue);
    });
  });
}
