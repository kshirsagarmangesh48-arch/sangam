import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/document_category_model.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentModel>> getDocuments({bool refresh = false});
  Future<DocumentModel> uploadDocument({
    required String name,
    String? description,
    required String category,
    required String filePath,
    List<int>? fileBytes,
    required String fileName,
  });
  Future<void> deleteDocument(String id);
  Future<List<DocumentCategoryModel>> getCategories({bool refresh = false});
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

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final ApiClient _apiClient;

  DocumentRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<DocumentModel>> getDocuments({bool refresh = false}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.documents,
        options: Options(
          extra: refresh ? {'refresh': true, 'noCache': true} : {},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List<dynamic>? ?? [];
        return list
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        return data
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to load documents from backend',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to fetch documents from server'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<DocumentModel> uploadDocument({
    required String name,
    String? description,
    required String category,
    required String filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('name', name.trim()));
      formData.fields.add(MapEntry('title', name.trim()));
      formData.fields.add(MapEntry('category', category.trim()));
      if (description != null && description.trim().isNotEmpty) {
        formData.fields.add(MapEntry('description', description.trim()));
      }

      if (!kIsWeb && filePath.isNotEmpty && await File(filePath).exists()) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        ));
      } else if (fileBytes != null && fileBytes.isNotEmpty) {
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
          ),
        ));
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.documents,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          return DocumentModel.fromJson(payload);
        }
      }
      return DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        category: category,
        fileUrl: ApiEndpoints.resolveDocumentUrl(fileName),
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: fileBytes?.length ?? 0,
        fileExtension: fileName.split('.').last.toLowerCase(),
        uploadedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to upload document to server'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.documents}/$id');
    } on DioException catch (e) {
      throw ApiException(
        message: _extractErrorMessage(e, 'Failed to delete document'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<DocumentCategoryModel>> getCategories({bool refresh = false}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.documentCategories,
        options: Options(
          extra: refresh ? {'refresh': true, 'noCache': true} : {},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          return list
              .map((item) =>
                  DocumentCategoryModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
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
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.documentCategories,
        data: {
          'name': name.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          if (iconName != null && iconName.isNotEmpty)
            'iconName': iconName,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return DocumentCategoryModel.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return DocumentCategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description?.trim() ?? '',
      iconName: iconName ?? 'folder',
      isDefault: false,
    );
  }

  @override
  Future<DocumentCategoryModel> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconName,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.documentCategories}/$id',
        data: {
          'name': name.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          if (iconName != null && iconName.isNotEmpty)
            'iconName': iconName,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return DocumentCategoryModel.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return DocumentCategoryModel(
      id: id,
      name: name.trim(),
      description: description?.trim() ?? '',
      iconName: iconName ?? 'folder',
      isDefault: false,
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.documentCategories}/$id');
    } catch (_) {}
  }

  String _extractErrorMessage(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map.containsKey('message') && map['message'] != null) {
        return map['message'].toString();
      }
    }
    return e.message ?? defaultMessage;
  }
}
