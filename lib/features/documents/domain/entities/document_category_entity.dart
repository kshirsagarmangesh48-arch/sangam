import 'package:equatable/equatable.dart';

class DocumentCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool isDefault;

  const DocumentCategoryEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.iconName = 'description',
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, description, iconName, isDefault];
}
