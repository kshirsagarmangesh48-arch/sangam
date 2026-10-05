import '../../domain/entities/document_category_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_data_source.dart';
import '../datasources/document_remote_data_source.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;
  final DocumentLocalDataSource localDataSource;

  DocumentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<DocumentEntity>> getDocuments({
    String? category,
    String? searchQuery,
    bool refresh = false,
  }) async {
    List<DocumentEntity> docs = [];

    try {
      docs = await remoteDataSource.getDocuments(refresh: refresh);
    } catch (_) {
      // Fallback to local storage if offline or remote error
      docs = await localDataSource.getDocuments();
    }

    return docs.where((doc) {
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        if (doc.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = doc.name.toLowerCase().contains(query);
        final matchCat = doc.category.toLowerCase().contains(query);
        final matchDesc = doc.description?.toLowerCase().contains(query) ?? false;
        final matchExt = doc.fileExtension.toLowerCase().contains(query);
        if (!matchName && !matchCat && !matchDesc && !matchExt) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<DocumentEntity> uploadDocument({
    required String name,
    String? description,
    required String category,
    required String filePath,
    List<int>? fileBytes,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    try {
      final uploaded = await remoteDataSource.uploadDocument(
        name: name,
        description: description,
        category: category,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      // Save copy to local dedicated cache
      await localDataSource.saveDocument(
        title: name,
        description: description,
        categoryId: category.toLowerCase().replaceAll(' ', '_'),
        categoryName: category,
        sourceFilePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        uploadedByRole: 'USER',
        uploadedByName: 'Me',
      );

      return uploaded;
    } catch (e) {
      // Save locally if server is offline or fails
      final local = await localDataSource.saveDocument(
        title: name,
        description: description,
        categoryId: category.toLowerCase().replaceAll(' ', '_'),
        categoryName: category,
        sourceFilePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        uploadedByRole: 'USER',
        uploadedByName: 'Me',
      );
      return local;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await remoteDataSource.deleteDocument(id);
    } catch (_) {}
    await localDataSource.deleteDocument(id);
  }

  @override
  Future<List<DocumentCategoryEntity>> getCategories({bool refresh = false}) async {
    try {
      return await remoteDataSource.getCategories(refresh: refresh);
    } catch (_) {
      return await localDataSource.getCategories();
    }
  }

  @override
  Future<DocumentCategoryEntity> createCategory({
    required String name,
    String? description,
    String? iconName,
  }) async {
    try {
      final cat = await remoteDataSource.createCategory(
        name: name,
        description: description,
        iconName: iconName,
      );
      await localDataSource.createCategory(
        name: name,
        description: description,
        iconName: iconName,
      );
      return cat;
    } catch (_) {
      return await localDataSource.createCategory(
        name: name,
        description: description,
        iconName: iconName,
      );
    }
  }

  @override
  Future<DocumentCategoryEntity> updateCategory(
    String id, {
    required String name,
    String? description,
    String? iconName,
  }) async {
    try {
      final cat = await remoteDataSource.updateCategory(
        id: id,
        name: name,
        description: description,
        iconName: iconName,
      );
      await localDataSource.updateCategory(
        id: id,
        name: name,
        description: description,
        iconName: iconName,
      );
      return cat;
    } catch (_) {
      return await localDataSource.updateCategory(
        id: id,
        name: name,
        description: description,
        iconName: iconName,
      );
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
    } catch (_) {}
    await localDataSource.deleteCategory(id);
  }
}
