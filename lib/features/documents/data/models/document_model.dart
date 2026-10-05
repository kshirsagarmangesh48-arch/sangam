import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    super.fileUrl,
    super.filePath,
    required super.fileName,
    required super.fileSizeBytes,
    required super.fileExtension,
    required super.uploadedAt,
    super.uploadedBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // Determine name/title
    final name = (json['name'] ?? json['title'] ?? 'Untitled Document').toString();

    // Determine description
    final description = json['description']?.toString();

    // Determine category
    String category = 'Common Property';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        category = (json['category']['name'] ?? 'Common Property').toString();
      } else {
        category = json['category'].toString();
      }
    } else if (json['categoryName'] != null) {
      category = json['categoryName'].toString();
    }

    // Determine file url & path (supports S3/DigitalOcean Spaces location property)
    String? rawUrl = json['fileUrl']?.toString() ??
        json['url']?.toString() ??
        json['location']?.toString() ??
        json['file_url']?.toString();
    final filePath = json['filePath']?.toString() ?? json['path']?.toString();

    // Determine file name (supports Spaces key/name)
    String fileName = (json['fileName'] ??
            json['originalName'] ??
            json['filename'] ??
            json['key'] ??
            '')
        .toString();
    if (fileName.isEmpty) {
      if (filePath != null && filePath.isNotEmpty) {
        fileName = filePath.split(RegExp(r'[/\\]')).last;
      } else if (rawUrl != null && rawUrl.isNotEmpty) {
        fileName = rawUrl.split('?').first.split('/').last;
      } else {
        fileName = 'document.pdf';
      }
    }

    String? fileUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      fileUrl = ApiEndpoints.resolveDocumentUrl(rawUrl);
    } else if (fileName.isNotEmpty && !fileName.endsWith('.bin')) {
      fileUrl = ApiEndpoints.resolveDocumentUrl(fileName);
    }

    // Determine extension
    String fileExtension = (json['fileExtension'] ?? json['fileType'] ?? '').toString();
    if (fileExtension.isEmpty && fileName.contains('.')) {
      fileExtension = fileName.split('.').last.toLowerCase();
    }
    if (fileExtension.isEmpty) fileExtension = 'pdf';

    // Determine file size
    int fileSizeBytes = 0;
    if (json['fileSizeBytes'] != null) {
      fileSizeBytes = int.tryParse(json['fileSizeBytes'].toString()) ?? 0;
    } else if (json['fileSize'] != null) {
      fileSizeBytes = int.tryParse(json['fileSize'].toString()) ?? 0;
    } else if (json['size'] != null) {
      fileSizeBytes = int.tryParse(json['size'].toString()) ?? 0;
    }

    // Determine uploaded date
    DateTime uploadedAt = DateTime.now();
    final rawDate = json['uploadedAt'] ?? json['createdAt'] ?? json['created_at'];
    if (rawDate != null) {
      uploadedAt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    final uploadedBy = json['uploadedBy']?.toString() ??
        json['uploadedByName']?.toString() ??
        (json['user'] is Map ? json['user']['name']?.toString() : null);

    return DocumentModel(
      id: (json['id'] ?? json['_id'] ?? 'doc_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      name: name,
      description: description,
      category: category,
      fileUrl: fileUrl,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      fileExtension: fileExtension,
      uploadedAt: uploadedAt,
      uploadedBy: uploadedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'category': category,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (filePath != null) 'filePath': filePath,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'fileExtension': fileExtension,
      'uploadedAt': uploadedAt.toIso8601String(),
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
    };
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      fileUrl: entity.fileUrl,
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileSizeBytes: entity.fileSizeBytes,
      fileExtension: entity.fileExtension,
      uploadedAt: entity.uploadedAt,
      uploadedBy: entity.uploadedBy,
    );
  }
}
