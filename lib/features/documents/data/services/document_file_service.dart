import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/api_endpoints.dart';

class DocumentFileService {
  final Dio dio;

  DocumentFileService({Dio? dio})
      : dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 5),
                followRedirects: true,
              ),
            );

  static const String rootFolderName = 'SangamVault';
  static const String docsSubFolder = 'Documents';
  static const String downloadsSubFolder = 'Downloads';

  /// Resolves the dedicated, isolated storage directory for documents.
  /// Completely separate from other app folders.
  Future<Directory> getDedicatedFolder({String? subFolder, String? category}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folderName = subFolder ?? docsSubFolder;

    String path = '${appDir.path}/$rootFolderName/$folderName';
    if (category != null && category.trim().isNotEmpty) {
      final sanitizedCategory = category.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      path = '$path/$sanitizedCategory';
    }

    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies an uploaded file into the dedicated separate folder
  Future<String> saveUploadedFile({
    required String sourcePath,
    required String fileName,
    required String category,
  }) async {
    if (kIsWeb) return sourcePath;

    final targetDir = await getDedicatedFolder(category: category);
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final targetFile = File('${targetDir.path}/$uniqueName');

    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      final copied = await sourceFile.copy(targetFile.path);
      return copied.path;
    }
    return sourcePath;
  }

  /// Saves raw bytes into the dedicated separate folder
  Future<String> saveBytes({
    required List<int> bytes,
    required String fileName,
    required String category,
  }) async {
    if (kIsWeb) return fileName;

    final targetDir = await getDedicatedFolder(category: category);
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    final targetFile = File('${targetDir.path}/$uniqueName');
    await targetFile.writeAsBytes(bytes);
    return targetFile.path;
  }

  /// Checks if a file is already downloaded and cached locally
  Future<File?> getCachedFile({
    required String docId,
    required String fileName,
    String? category,
  }) async {
    if (kIsWeb) return null;

    final downloadsDir = await getDedicatedFolder(
      subFolder: downloadsSubFolder,
      category: category,
    );
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${downloadsDir.path}/${docId}_$sanitizedName');

    if (await file.exists() && (await file.length()) > 0) {
      return file;
    }
    return null;
  }

  /// Downloads a remote document to the dedicated Downloads folder with progress tracking
  Future<File> downloadDocument({
    required String url,
    required String docId,
    required String fileName,
    String? category,
    void Function(int received, int total)? onProgress,
  }) async {
    final downloadsDir = await getDedicatedFolder(
      subFolder: downloadsSubFolder,
      category: category,
    );
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final savePath = '${downloadsDir.path}/${docId}_$sanitizedName';

    final targetFile = File(savePath);
    if (await targetFile.exists() && (await targetFile.length()) > 0) {
      // Already cached!
      return targetFile;
    }

    final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);

    await dio.download(
      resolvedUrl,
      savePath,
      onReceiveProgress: onProgress,
      options: Options(
        headers: const {},
      ),
    );

    return File(savePath);
  }

  /// Deletes a file from the dedicated storage
  Future<void> deleteFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty || kIsWeb) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
