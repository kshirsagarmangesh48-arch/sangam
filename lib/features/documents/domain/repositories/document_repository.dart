import '../entities/document_category_entity.dart';
import '../entities/document_entity.dart';

abstract class DocumentRepository {
  Future<List<DocumentEntity>> getDocuments({
    String? category,
    String? searchQuery,
    bool refresh = false,
  });

  Future<DocumentEntity> uploadDocument({
    required String name,
    String? description,
    required String category,
    required String filePath,
    List<int>? fileBytes,
    required String fileName,
    required int fileSizeBytes,
  });

  Future<void> deleteDocument(String id);

  Future<List<DocumentCategoryEntity>> getCategories({bool refresh = false});

  Future<DocumentCategoryEntity> createCategory({
    required String name,
    String? description,
    String? iconName,
  });

  Future<DocumentCategoryEntity> updateCategory(
    String id, {
    required String name,
    String? description,
    String? iconName,
  });

  Future<void> deleteCategory(String id);
}
