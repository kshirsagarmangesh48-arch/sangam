import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/document_category_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import 'add_category_bottom_sheet.dart';

class ManageCategoriesBottomSheet extends StatelessWidget {
  final bool isAdmin;

  const ManageCategoriesBottomSheet({super.key, required this.isAdmin});

  static Future<void> show(BuildContext context, {required bool isAdmin}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DocumentBloc>(),
        child: ManageCategoriesBottomSheet(isAdmin: isAdmin),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'home_work':
        return Icons.home_work_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'folder':
        return Icons.folder_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                      Icons.category_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Categories',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Organize and group your files',
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
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              size: 32,
                              color: colors.outline,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Categories Yet',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your first category using the button below to group your documents.',
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final icon = _resolveIcon(cat.iconName);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: colors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (cat.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
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
                              ],
                            ),
                          ),
                          if (isAdmin) ...[
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: colors.primary,
                              ),
                              tooltip: 'Edit category',
                              onPressed: () {
                                AddCategoryBottomSheet.show(
                                  context,
                                  category: cat,
                                );
                              },
                            ),
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
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Add Category Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Category'),
              onPressed: () {
                AddCategoryBottomSheet.show(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
