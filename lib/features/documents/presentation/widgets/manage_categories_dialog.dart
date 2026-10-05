import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/document_category_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';

class ManageCategoriesDialog extends StatefulWidget {
  final bool isAdmin;

  const ManageCategoriesDialog({super.key, required this.isAdmin});

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIcon = 'description';
  bool _isCreatingNew = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'home_work', 'label': 'Property', 'icon': Icons.home_work_rounded},
    {'name': 'badge', 'label': 'Member', 'icon': Icons.badge_rounded},
    {'name': 'directions_car', 'label': 'Vehicle', 'icon': Icons.directions_car_rounded},
    {'name': 'gavel', 'label': 'Legal', 'icon': Icons.gavel_rounded},
    {'name': 'medical_services', 'label': 'Medical', 'icon': Icons.medical_services_rounded},
    {'name': 'receipt_long', 'label': 'Tax & Bill', 'icon': Icons.receipt_long_rounded},
    {'name': 'folder', 'label': 'Folder', 'icon': Icons.folder_rounded},
    {'name': 'description', 'label': 'Document', 'icon': Icons.description_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitNewCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category name')),
      );
      return;
    }

    context.read<DocumentBloc>().add(
          CreateDocumentCategoryRequested(
            name: name,
            description: _descController.text.trim(),
            iconName: _selectedIcon,
          ),
        );

    _nameController.clear();
    _descController.clear();
    setState(() {
      _isCreatingNew = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category "$name" added successfully')),
    );
  }

  IconData _resolveIcon(String iconName) {
    for (final opt in _iconOptions) {
      if (opt['name'] == iconName) {
        return opt['icon'] as IconData;
      }
    }
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          Icons.category_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Document Categories',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Organize files into distinct categories for common property, member records, and more.',
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Categories List
              Expanded(
                child: BlocBuilder<DocumentBloc, DocumentState>(
                  builder: (context, state) {
                    final categories = state is DocumentLoaded
                        ? state.categories
                        : <DocumentCategoryEntity>[];

                    if (categories.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 42,
                                color: colors.outline,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No categories yet',
                                style: text.titleSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click "Create New Category" below to add categories.',
                                style: text.bodySmall?.copyWith(
                                  color: colors.outline,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final icon = _resolveIcon(cat.iconName);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: colors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (cat.description.isNotEmpty)
                                      Text(
                                        cat.description,
                                        style: text.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (widget.isAdmin)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: colors.error,
                                  ),
                                  tooltip: 'Delete category',
                                  onPressed: () {
                                    context.read<DocumentBloc>().add(
                                          DeleteDocumentCategoryRequested(cat.id),
                                        );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (_isCreatingNew) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Category',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name *',
                          hintText: 'e.g. Society Tax, Vehicle RC',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Brief note about this category',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select Icon:',
                        style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _iconOptions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final item = _iconOptions[idx];
                            final isSel = item['name'] == _selectedIcon;
                            return InkWell(
                              onTap: () => setState(() => _selectedIcon = item['name']),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? colors.primary
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? colors.primary : colors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      size: 16,
                                      color: isSel ? colors.onPrimary : colors.onSurface,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['label'] as String,
                                      style: text.bodySmall?.copyWith(
                                        color: isSel ? colors.onPrimary : colors.onSurface,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isCreatingNew = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _submitNewCategory,
                            child: const Text('Add Category'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (widget.isAdmin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create New Category'),
                    onPressed: () => setState(() => _isCreatingNew = true),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
