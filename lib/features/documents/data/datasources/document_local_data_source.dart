import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_category_model.dart';
import '../models/document_model.dart';
import '../services/document_file_service.dart';

abstract class DocumentLocalDataSource {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel> saveDocument({
    required String title,
    String? description,
    required String categoryId,
    required String categoryName,
    int? memberId,
    String? memberName,
    String? sourceFilePath,
    List<int>? fileBytes,
    required String fileName,
    required int fileSizeBytes,
    required String uploadedByRole,
    required String uploadedByName,
  });
  Future<void> deleteDocument(String id);
  Future<List<DocumentCategoryModel>> getCategories();
  Future<DocumentCategoryModel> createCategory({
    required String name,
    String? description,
    String? iconName,
  });
  Future<DocumentCategoryModel> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconName,
  });
  Future<void> deleteCategory(String id);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final SharedPreferences prefs;
  final DocumentFileService fileService;

  static const String _docsPrefsKey = 'sangam_saved_documents_v1';
  static const String _categoriesPrefsKey = 'sangam_document_categories_v2';

  DocumentLocalDataSourceImpl({
    required this.prefs,
    required this.fileService,
  }) {
    // Purge any old v1 hardcoded categories
    if (prefs.containsKey('sangam_document_categories_v1')) {
      prefs.remove('sangam_document_categories_v1');
    }
  }

  @override
  Future<List<DocumentCategoryModel>> getCategories() async {
    final raw = prefs.getString(_categoriesPrefsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) =>
              DocumentCategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DocumentCategoryModel> createCategory({
    required String name,
    String? description,
    String? iconName,
  }) async {
    final categories = await getCategories();
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCategory = DocumentCategoryModel(
      id: newId,
      name: name.trim(),
      description: description?.trim() ?? '',
      iconName: iconName ?? 'description',
      isDefault: false,
    );

    categories.add(newCategory);
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesPrefsKey, encoded);
    return newCategory;
  }

  @override
  Future<DocumentCategoryModel> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconName,
  }) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == id);
    final updated = DocumentCategoryModel(
      id: id,
      name: name.trim(),
      description: description?.trim() ?? '',
      iconName: iconName ?? 'folder',
      isDefault: false,
    );

    if (index != -1) {
      categories[index] = updated;
    } else {
      categories.add(updated);
    }

    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesPrefsKey, encoded);
    return updated;
  }

  @override
  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    categories.removeWhere((c) => c.id == id);
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesPrefsKey, encoded);
  }

  @override
  Future<List<DocumentModel>> getDocuments() async {
    final raw = prefs.getString(_docsPrefsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DocumentModel> saveDocument({
    required String title,
    String? description,
    required String categoryId,
    required String categoryName,
    int? memberId,
    String? memberName,
    String? sourceFilePath,
    List<int>? fileBytes,
    required String fileName,
    required int fileSizeBytes,
    required String uploadedByRole,
    required String uploadedByName,
  }) async {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'pdf';

    String savedFilePath = sourceFilePath ?? '';

    // Save to completely separate folder: SangamVault/Documents/<Category>
    if (!kIsWeb) {
      if (sourceFilePath != null && sourceFilePath.isNotEmpty) {
        savedFilePath = await fileService.saveUploadedFile(
          sourcePath: sourceFilePath,
          fileName: fileName,
          category: categoryName,
        );
      } else if (fileBytes != null && fileBytes.isNotEmpty) {
        savedFilePath = await fileService.saveBytes(
          bytes: fileBytes,
          fileName: fileName,
          category: categoryName,
        );
      }
    }

    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final newDoc = DocumentModel(
      id: docId,
      name: title.trim(),
      description: description?.trim(),
      category: categoryName,
      fileName: fileName,
      filePath: savedFilePath,
      fileSizeBytes: fileSizeBytes,
      fileExtension: extension,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedByName,
    );

    final currentDocs = await getDocuments();
    currentDocs.insert(0, newDoc);

    final encoded = jsonEncode(currentDocs.map((d) => d.toJson()).toList());
    await prefs.setString(_docsPrefsKey, encoded);

    return newDoc;
  }

  @override
  Future<void> deleteDocument(String id) async {
    final currentDocs = await getDocuments();
    final index = currentDocs.indexWhere((d) => d.id == id);
    if (index != -1) {
      final doc = currentDocs[index];
      await fileService.deleteFile(doc.filePath);
      currentDocs.removeAt(index);
      final encoded = jsonEncode(currentDocs.map((d) => d.toJson()).toList());
      await prefs.setString(_docsPrefsKey, encoded);
    }
  }
}
