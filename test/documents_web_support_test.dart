import 'package:expenses/core/constants/api_endpoints.dart';
import 'package:expenses/features/documents/data/models/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Documents Web Support & Model Tests', () {
    test('Resolves web document URLs correctly for relative and absolute paths', () {
      expect(
        ApiEndpoints.resolveDocumentUrl('test_doc.pdf'),
        equals('https://api.makeinsatara.in/uploads/sangam-home/documents/test_doc.pdf'),
      );

      expect(
        ApiEndpoints.resolveDocumentUrl('uploads/sangam-home/documents/receipt.png'),
        equals('https://api.makeinsatara.in/uploads/sangam-home/documents/receipt.png'),
      );

      expect(
        ApiEndpoints.resolveDocumentUrl('https://custom-cdn.com/file.pdf'),
        equals('https://custom-cdn.com/file.pdf'),
      );
    });

    test('DocumentModel parses web payload with fileUrl and without local filePath', () {
      final json = {
        'id': 'doc_web_123',
        'name': 'Apartment Lease',
        'description': 'Signed agreement',
        'category': 'Legal',
        'fileUrl': 'https://api.makeinsatara.in/uploads/sangam-home/documents/lease.pdf',
        'fileName': 'lease.pdf',
        'fileSizeBytes': 1048576,
        'fileExtension': 'pdf',
        'uploadedAt': '2026-10-07T12:00:00.000Z',
        'uploadedBy': 'Admin',
      };

      final doc = DocumentModel.fromJson(json);

      expect(doc.id, equals('doc_web_123'));
      expect(doc.name, equals('Apartment Lease'));
      expect(doc.isPdf, isTrue);
      expect(doc.isImage, isFalse);
      expect(doc.fileUrl, equals('https://api.makeinsatara.in/uploads/sangam-home/documents/lease.pdf'));
      expect(doc.filePath, isNull);
      expect(doc.formattedFileSize, equals('1.0 MB'));
    });

    test('DocumentModel correctly recognizes image extensions', () {
      final images = ['photo.jpg', 'scan.jpeg', 'doc.png', 'receipt.webp'];
      for (final img in images) {
        final doc = DocumentModel(
          id: '1',
          name: img,
          category: 'Receipts',
          fileName: img,
          fileSizeBytes: 2048,
          fileExtension: img.split('.').last,
          uploadedAt: DateTime.now(),
        );
        expect(doc.isImage, isTrue, reason: '$img should be recognized as an image');
        expect(doc.isPdf, isFalse);
      }
    });
  });
}
