import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? fileUrl;
  final String? filePath;
  final String fileName;
  final int fileSizeBytes;
  final String fileExtension;
  final DateTime uploadedAt;
  final String? uploadedBy;

  const DocumentEntity({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.fileUrl,
    this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileExtension,
    required this.uploadedAt,
    this.uploadedBy,
  });

  // Backward compatibility alias
  String get title => name;
  String get categoryName => category;
  String get categoryId => category.toLowerCase().replaceAll(' ', '_');

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(fileExtension.toLowerCase());

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        fileUrl,
        filePath,
        fileName,
        fileSizeBytes,
        fileExtension,
        uploadedAt,
        uploadedBy,
      ];
}
