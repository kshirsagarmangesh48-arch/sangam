import 'package:equatable/equatable.dart';
import '../../domain/entities/document_category_entity.dart';
import '../../domain/entities/document_entity.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {
  const DocumentInitial();
}

class DocumentLoading extends DocumentState {
  const DocumentLoading();
}

class DocumentLoaded extends DocumentState {
  final List<DocumentEntity> allDocuments;
  final List<DocumentEntity> filteredDocuments;
  final List<DocumentCategoryEntity> categories;
  final String selectedCategory;
  final String searchQuery;

  const DocumentLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  DocumentLoaded copyWith({
    List<DocumentEntity>? allDocuments,
    List<DocumentEntity>? filteredDocuments,
    List<DocumentCategoryEntity>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return DocumentLoaded(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get totalDocsCount => allDocuments.length;

  int get categoriesCount => categories.length;

  int get totalSizeBytes =>
      allDocuments.fold<int>(0, (sum, item) => sum + item.fileSizeBytes);

  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        allDocuments,
        filteredDocuments,
        categories,
        selectedCategory,
        searchQuery,
      ];
}

class DocumentOperationSuccess extends DocumentState {
  final String message;

  const DocumentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError(this.message);

  @override
  List<Object?> get props => [message];
}
