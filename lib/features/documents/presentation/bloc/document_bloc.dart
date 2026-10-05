import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/document_category_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository documentRepository;

  DocumentBloc({required this.documentRepository})
      : super(const DocumentInitial()) {
    on<FetchDocumentsRequested>(_onFetchDocumentsRequested);
    on<RefreshDocumentsRequested>(_onRefreshDocumentsRequested);
    on<FilterCategorySelected>(_onFilterCategorySelected);
    on<SearchDocumentsChanged>(_onSearchDocumentsChanged);
    on<UploadDocumentRequested>(_onUploadDocumentRequested);
    on<DeleteDocumentRequested>(_onDeleteDocumentRequested);
    on<CreateDocumentCategoryRequested>(_onCreateDocumentCategoryRequested);
    on<UpdateDocumentCategoryRequested>(_onUpdateDocumentCategoryRequested);
    on<DeleteDocumentCategoryRequested>(_onDeleteDocumentCategoryRequested);
  }

  List<DocumentEntity> _applyFilters({
    required List<DocumentEntity> allDocs,
    required String category,
    required String searchQuery,
  }) {
    return allDocs.where((doc) {
      if (category != 'All') {
        if (doc.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (searchQuery.trim().isNotEmpty) {
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

  Future<void> _onFetchDocumentsRequested(
    FetchDocumentsRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    try {
      final categories = await documentRepository.getCategories();
      final allDocs = await documentRepository.getDocuments();

      final selectedCategory = event.category ?? 'All';
      final searchQuery = event.searchQuery ?? '';
      final filtered = _applyFilters(
        allDocs: allDocs,
        category: selectedCategory,
        searchQuery: searchQuery,
      );

      emit(
        DocumentLoaded(
          allDocuments: allDocs,
          filteredDocuments: filtered,
          categories: categories,
          selectedCategory: selectedCategory,
          searchQuery: searchQuery,
        ),
      );
    } catch (e) {
      emit(DocumentError('Failed to load documents: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDocumentsRequested(
    RefreshDocumentsRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final categories = await documentRepository.getCategories(refresh: true);
      final allDocs = await documentRepository.getDocuments(refresh: true);

      String selectedCategory = event.category ?? 'All';
      String searchQuery = event.searchQuery ?? '';
      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        selectedCategory = event.category ?? current.selectedCategory;
        searchQuery = event.searchQuery ?? current.searchQuery;
      }

      final filtered = _applyFilters(
        allDocs: allDocs,
        category: selectedCategory,
        searchQuery: searchQuery,
      );

      emit(
        DocumentLoaded(
          allDocuments: allDocs,
          filteredDocuments: filtered,
          categories: categories,
          selectedCategory: selectedCategory,
          searchQuery: searchQuery,
        ),
      );
    } catch (e) {
      emit(DocumentError('Failed to refresh documents: ${e.toString()}'));
    }
  }

  void _onFilterCategorySelected(
    FilterCategorySelected event,
    Emitter<DocumentState> emit,
  ) {
    if (state is DocumentLoaded) {
      final current = state as DocumentLoaded;
      final filtered = _applyFilters(
        allDocs: current.allDocuments,
        category: event.category,
        searchQuery: current.searchQuery,
      );
      emit(
        current.copyWith(
          selectedCategory: event.category,
          filteredDocuments: filtered,
        ),
      );
    }
  }

  void _onSearchDocumentsChanged(
    SearchDocumentsChanged event,
    Emitter<DocumentState> emit,
  ) {
    if (state is DocumentLoaded) {
      final current = state as DocumentLoaded;
      final filtered = _applyFilters(
        allDocs: current.allDocuments,
        category: current.selectedCategory,
        searchQuery: event.query,
      );
      emit(
        current.copyWith(
          searchQuery: event.query,
          filteredDocuments: filtered,
        ),
      );
    }
  }

  Future<void> _onUploadDocumentRequested(
    UploadDocumentRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await documentRepository.uploadDocument(
        name: event.name,
        description: event.description,
        category: event.category,
        filePath: event.filePath,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
        fileSizeBytes: event.fileSizeBytes,
      );

      // Reload documents and categories
      final categories = await documentRepository.getCategories();
      final allDocs = await documentRepository.getDocuments();

      String selectedCat = 'All';
      String searchQ = '';
      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        selectedCat = current.selectedCategory;
        searchQ = current.searchQuery;
      }

      final filtered = _applyFilters(
        allDocs: allDocs,
        category: selectedCat,
        searchQuery: searchQ,
      );

      emit(
        DocumentLoaded(
          allDocuments: allDocs,
          filteredDocuments: filtered,
          categories: categories,
          selectedCategory: selectedCat,
          searchQuery: searchQ,
        ),
      );
    } catch (e) {
      emit(DocumentError('Failed to upload document: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDocumentRequested(
    DeleteDocumentRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await documentRepository.deleteDocument(event.id);

      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        final updatedAll = current.allDocuments.where((d) => d.id != event.id).toList();
        final filtered = _applyFilters(
          allDocs: updatedAll,
          category: current.selectedCategory,
          searchQuery: current.searchQuery,
        );
        emit(
          current.copyWith(
            allDocuments: updatedAll,
            filteredDocuments: filtered,
          ),
        );
      } else {
        add(const FetchDocumentsRequested());
      }
    } catch (e) {
      emit(DocumentError('Failed to delete document: ${e.toString()}'));
    }
  }

  Future<void> _onCreateDocumentCategoryRequested(
    CreateDocumentCategoryRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final newCat = await documentRepository.createCategory(
        name: event.name,
        description: event.description,
        iconName: event.iconName,
      );

      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        final updatedCats = List<DocumentCategoryEntity>.from(current.categories)
          ..add(newCat);
        emit(current.copyWith(categories: updatedCats));
      } else {
        add(const FetchDocumentsRequested());
      }
    } catch (e) {
      emit(DocumentError('Failed to create category: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDocumentCategoryRequested(
    UpdateDocumentCategoryRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final updatedCat = await documentRepository.updateCategory(
        event.id,
        name: event.name,
        description: event.description,
        iconName: event.iconName,
      );

      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        final index = current.categories.indexWhere((c) => c.id == event.id);
        final updatedCats = List<DocumentCategoryEntity>.from(current.categories);
        if (index != -1) {
          updatedCats[index] = updatedCat;
        } else {
          updatedCats.add(updatedCat);
        }
        emit(current.copyWith(categories: updatedCats));
      } else {
        add(const FetchDocumentsRequested());
      }
    } catch (e) {
      emit(DocumentError('Failed to update category: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDocumentCategoryRequested(
    DeleteDocumentCategoryRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await documentRepository.deleteCategory(event.id);

      if (state is DocumentLoaded) {
        final current = state as DocumentLoaded;
        final updatedCats =
            current.categories.where((c) => c.id != event.id).toList();
        final selectedCat =
            current.selectedCategory == event.id ? 'All' : current.selectedCategory;
        final filtered = _applyFilters(
          allDocs: current.allDocuments,
          category: selectedCat,
          searchQuery: current.searchQuery,
        );
        emit(
          current.copyWith(
            categories: updatedCats,
            selectedCategory: selectedCat,
            filteredDocuments: filtered,
          ),
        );
      } else {
        add(const FetchDocumentsRequested());
      }
    } catch (e) {
      emit(DocumentError('Failed to delete category: ${e.toString()}'));
    }
  }
}
