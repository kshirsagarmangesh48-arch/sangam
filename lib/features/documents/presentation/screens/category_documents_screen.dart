import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/document_category_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import '../widgets/document_card.dart';
import '../widgets/upload_document_sheet.dart';

class CategoryDocumentsScreen extends StatefulWidget {
  final String categoryName;
  final DocumentCategoryEntity? categoryEntity;
  final SangamUserEntity user;
  final Color? accentColor;

  const CategoryDocumentsScreen({
    super.key,
    required this.categoryName,
    this.categoryEntity,
    required this.user,
    this.accentColor,
  });

  @override
  State<CategoryDocumentsScreen> createState() =>
      _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _resolveCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'home_work':
        return Icons.home_work_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'folder':
        return Icons.folder_rounded;
      default:
        return Icons.folder_special_rounded;
    }
  }

  Color _resolveCategoryColor(BuildContext context) {
    if (widget.accentColor != null) return widget.accentColor!;
    if (widget.categoryName == 'All') return context.colors.primary;

    const palette = [
      Color(0xFF2563EB), // Royal Blue
      Color(0xFF0D9488), // Deep Teal
      Color(0xFF7C3AED), // Violet
      Color(0xFFEA580C), // Vivid Orange
      Color(0xFF059669), // Emerald
      Color(0xFFDB2777), // Pink
      Color(0xFFD97706), // Amber
      Color(0xFF4F46E5), // Indigo
      Color(0xFF0284C7), // Sky Blue
    ];
    final hash = widget.categoryName.hashCode.abs();
    return palette[hash % palette.length];
  }

  String _formatTotalSize(List<DocumentEntity> docs) {
    final totalBytes = docs.fold<int>(0, (sum, d) => sum + d.fileSizeBytes);
    if (totalBytes <= 0) return '0 KB';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UploadDocumentSheet(
        user: widget.user,
        initialCategory:
            widget.categoryName != 'All' ? widget.categoryName : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final categoryColor = _resolveCategoryColor(context);
    final icon = _resolveCategoryIcon(widget.categoryEntity?.iconName);
    final isAll = widget.categoryName.toLowerCase() == 'all';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAll ? 'All Documents' : widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<DocumentBloc>().add(
                    RefreshDocumentsRequested(
                      category: widget.categoryName,
                    ),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Upload to this Category',
            onPressed: () => _showUploadSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload_rounded),
        label: Text(
          isAll ? 'Upload Document' : 'Upload to ${widget.categoryName}',
        ),
        onPressed: () => _showUploadSheet(context),
      ),
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading && state is! DocumentLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = state is DocumentLoaded ? state.allDocuments : <DocumentEntity>[];

          // Filter documents for this specific category
          final categoryDocs = isAll
              ? allDocs
              : allDocs
                  .where((d) =>
                      d.category.trim().toLowerCase() ==
                      widget.categoryName.trim().toLowerCase())
                  .toList();

          // Apply in-page search query
          final displayedDocs = _searchQuery.trim().isEmpty
              ? categoryDocs
              : categoryDocs.where((d) {
                  final q = _searchQuery.trim().toLowerCase();
                  return d.name.toLowerCase().contains(q) ||
                      (d.description != null &&
                          d.description!.toLowerCase().contains(q)) ||
                      d.fileName.toLowerCase().contains(q);
                }).toList();

          final pdfCount = categoryDocs.where((d) => d.isPdf).length;
          final imageCount = categoryDocs.where((d) => d.isImage).length;
          final formattedSize = _formatTotalSize(categoryDocs);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(
                    RefreshDocumentsRequested(
                      category: widget.categoryName,
                    ),
                  );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Hero Header Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryColor.withValues(alpha: 0.15),
                                categoryColor.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Badge
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: categoryColor.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      isAll ? Icons.grid_view_rounded : icon,
                                      color: categoryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Title & Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAll
                                              ? 'All Vault Documents'
                                              : widget.categoryName,
                                          style: text.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (widget.categoryEntity?.description != null &&
                                            widget.categoryEntity!.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.categoryEntity!.description,
                                            style: text.bodySmall?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Manage and access all documents in this category',
                                            style: text.bodySmall?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Quick Stat Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStatPill(
                                    icon: Icons.insert_drive_file_outlined,
                                    label:
                                        '${categoryDocs.length} ${categoryDocs.length == 1 ? 'File' : 'Files'}',
                                    color: categoryColor,
                                    context: context,
                                  ),
                                  _buildStatPill(
                                    icon: Icons.picture_as_pdf_outlined,
                                    label: '$pdfCount PDFs',
                                    color: const Color(0xFFDC2626),
                                    context: context,
                                  ),
                                  _buildStatPill(
                                    icon: Icons.image_outlined,
                                    label: '$imageCount Images',
                                    color: const Color(0xFF7C3AED),
                                    context: context,
                                  ),
                                  _buildStatPill(
                                    icon: Icons.data_usage_rounded,
                                    label: formattedSize,
                                    color: colors.onSurfaceVariant,
                                    context: context,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search in ${widget.categoryName}...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: colors.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              displayedDocs.isEmpty
                                  ? 'Documents'
                                  : 'Documents (${displayedDocs.length})',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text('Clear search'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Documents List or Empty State
                if (displayedDocs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: 40,
                                color: categoryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No documents matching "$_searchQuery"'
                                  : 'No documents in "${widget.categoryName}" yet',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload PDFs or Images (up to 5MB) into this category to view and organize them here.',
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: categoryColor,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: Text('Upload to ${widget.categoryName}'),
                              onPressed: () => _showUploadSheet(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = displayedDocs[index];
                          return DocumentCard(
                            document: doc,
                            canDelete: widget.user.isAdmin ||
                                doc.uploadedBy == widget.user.name,
                            onTap: () => DocumentCard.openDirectly(context, doc),
                            onDelete: () {
                              context
                                  .read<DocumentBloc>()
                                  .add(DeleteDocumentRequested(doc.id));
                            },
                          );
                        },
                        childCount: displayedDocs.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
