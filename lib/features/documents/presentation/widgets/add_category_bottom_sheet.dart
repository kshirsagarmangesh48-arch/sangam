import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/document_category_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  final DocumentCategoryEntity? category;

  const AddCategoryBottomSheet({super.key, this.category});

  static Future<String?> show(
    BuildContext context, {
    DocumentCategoryEntity? category,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>(),
        child: AddCategoryBottomSheet(category: category),
      ),
    );
  }

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIcon = 'folder';

  final List<Map<String, dynamic>> _iconOptions = const [
    {'name': 'folder', 'label': 'Folder', 'icon': Icons.folder_rounded},
    {'name': 'home_work', 'label': 'Property', 'icon': Icons.home_work_rounded},
    {'name': 'badge', 'label': 'Member', 'icon': Icons.badge_rounded},
    {'name': 'receipt_long', 'label': 'Tax & Bill', 'icon': Icons.receipt_long_rounded},
    {'name': 'directions_car', 'label': 'Vehicle', 'icon': Icons.directions_car_rounded},
    {'name': 'gavel', 'label': 'Legal', 'icon': Icons.gavel_rounded},
    {'name': 'medical_services', 'label': 'Medical', 'icon': Icons.medical_services_rounded},
    {'name': 'description', 'label': 'Document', 'icon': Icons.description_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descController.text = widget.category!.description;
      _selectedIcon = widget.category!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    if (widget.category != null) {
      context.read<DocumentBloc>().add(
            UpdateDocumentCategoryRequested(
              id: widget.category!.id,
              name: name,
              description: description.isNotEmpty ? description : null,
              iconName: _selectedIcon,
            ),
          );
    } else {
      context.read<DocumentBloc>().add(
            CreateDocumentCategoryRequested(
              name: name,
              description: description.isNotEmpty ? description : null,
              iconName: _selectedIcon,
            ),
          );
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.category != null;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: bottomInset + 20,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_note_rounded
                              : Icons.create_new_folder_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Category' : 'Add New Category',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update category name, icon or details'
                                : 'Organize documents into dedicated categories',
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category Name Field
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. Property Deeds, Vehicle RC, Tax Returns',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  if (val.trim().toLowerCase() == 'all') {
                    return '"All" is a reserved filter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description Field
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description about documents in this category',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Icon Selector
              Text(
                'Choose Icon',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _iconOptions[idx];
                    final isSelected = item['name'] == _selectedIcon;

                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = item['name']),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 18,
                              color: isSelected ? colors.onPrimary : colors.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['label'] as String,
                              style: text.bodySmall?.copyWith(
                                color: isSelected ? colors.onPrimary : colors.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(isEditing ? Icons.save_rounded : Icons.check_rounded),
                      label: Text(isEditing ? 'Save Changes' : 'Add Category'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
