import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class FetchDocumentsRequested extends DocumentEvent {
  final String? category;
  final String? searchQuery;

  const FetchDocumentsRequested({
    this.category,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [category, searchQuery];
}

class RefreshDocumentsRequested extends DocumentEvent {
  final String? category;
  final String? searchQuery;

  const RefreshDocumentsRequested({
    this.category,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [category, searchQuery];
}

class FilterCategorySelected extends DocumentEvent {
  final String category;

  const FilterCategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchDocumentsChanged extends DocumentEvent {
  final String query;

  const SearchDocumentsChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class UploadDocumentRequested extends DocumentEvent {
  final String name;
  final String? description;
  final String category;
  final String filePath;
  final List<int>? fileBytes;
  final String fileName;
  final int fileSizeBytes;

  const UploadDocumentRequested({
    required this.name,
    this.description,
    required this.category,
    required this.filePath,
    this.fileBytes,
    required this.fileName,
    required this.fileSizeBytes,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        category,
        filePath,
        fileName,
        fileSizeBytes,
      ];
}

class DeleteDocumentRequested extends DocumentEvent {
  final String id;

  const DeleteDocumentRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateDocumentCategoryRequested extends DocumentEvent {
  final String name;
  final String? description;
  final String? iconName;

  const CreateDocumentCategoryRequested({
    required this.name,
    this.description,
    this.iconName,
  });

  @override
  List<Object?> get props => [name, description, iconName];
}

class DeleteDocumentCategoryRequested extends DocumentEvent {
  final String id;

  const DeleteDocumentCategoryRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateDocumentCategoryRequested extends DocumentEvent {
  final String id;
  final String name;
  final String? description;
  final String? iconName;

  const UpdateDocumentCategoryRequested({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
  });

  @override
  List<Object?> get props => [id, name, description, iconName];
}
