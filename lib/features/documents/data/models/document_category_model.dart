import '../../domain/entities/document_category_entity.dart';

class DocumentCategoryModel extends DocumentCategoryEntity {
  const DocumentCategoryModel({
    required super.id,
    required super.name,
    super.description = '',
    super.iconName = 'description',
    super.isDefault = false,
  });

  factory DocumentCategoryModel.fromJson(Map<String, dynamic> json) {
    return DocumentCategoryModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? json['icon'] ?? 'folder').toString(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'isDefault': isDefault,
    };
  }

  factory DocumentCategoryModel.fromEntity(DocumentCategoryEntity entity) {
    return DocumentCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      iconName: entity.iconName,
      isDefault: entity.isDefault,
    );
  }
}
