import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/manage_categories_bottom_sheet.dart';
import '../widgets/upload_document_sheet.dart';
import 'category_documents_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final SangamUserEntity user;

  const DocumentsScreen({super.key, required this.user});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<DocumentBloc>().add(const FetchDocumentsRequested());
    });
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UploadDocumentSheet(user: widget.user),
    );
  }

  void _showManageCategoriesSheet(BuildContext context) {
    ManageCategoriesBottomSheet.show(context, isAdmin: widget.user.isAdmin);
  }

  IconData _resolveCategoryIcon(String iconName) {
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
        return Icons.description_rounded;
    }
  }

  Color _resolveCategoryColor(int index) {
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
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Documents',
            onPressed: () {
              context.read<DocumentBloc>().add(
                    const RefreshDocumentsRequested(),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking for updated documents from server...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          if (widget.user.isAdmin)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Manage Categories',
              onPressed: () => _showManageCategoriesSheet(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload Document'),
      ),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DocumentBloc>()
                          .add(const FetchDocumentsRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final loaded = state is DocumentLoaded
              ? state
              : const DocumentLoaded(
                  allDocuments: [],
                  filteredDocuments: [],
                  categories: [],
                );

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(
                    const RefreshDocumentsRequested(),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Overview Banner
                  _buildStatsRow(context, loaded),
                  const SizedBox(height: 24),

                  // Categories Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Categories',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${loaded.categories.length}',
                              style: text.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.user.isAdmin)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Category'),
                          onPressed: () => AddCategoryBottomSheet.show(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Categories Grid
                  _buildCategoryGrid(context, loaded),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, DocumentLoaded state) {
    final colors = context.colors;
    final categories = state.categories;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    final hasAddCard = widget.user.isAdmin;
    final totalItems = 1 + categories.length + (hasAddCard ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // 1. "All Documents" Card
        if (index == 0) {
          final count = state.allDocuments.length;

          return _CategoryGridCard(
            title: 'All Documents',
            subtitle: '$count ${count == 1 ? 'file' : 'files'}',
            icon: Icons.grid_view_rounded,
            color: colors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDocumentsScreen(
                    categoryName: 'All',
                    user: widget.user,
                  ),
                ),
              );
            },
          );
        }

        // 2. "+ Add Category" Card for Admin (at the end)
        if (hasAddCard && index == totalItems - 1) {
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => AddCategoryBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Category',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create new folder',
                        style: context.text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // 3. Dynamic Category Card
        final catIndex = index - 1;
        final cat = categories[catIndex];
        final count = state.allDocuments
            .where((d) => d.category.toLowerCase() == cat.name.toLowerCase())
            .length;
        final icon = _resolveCategoryIcon(cat.iconName);
        final color = _resolveCategoryColor(catIndex);

        return _CategoryGridCard(
          title: cat.name,
          subtitle: '$count ${count == 1 ? 'file' : 'files'}',
          icon: icon,
          color: color,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryDocumentsScreen(
                  categoryName: cat.name,
                  categoryEntity: cat,
                  user: widget.user,
                  accentColor: color,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, DocumentLoaded state) {
    final docs = state.allDocuments;
    final totalCount = docs.length;
    final pdfCount = docs.where((d) => d.isPdf).length;
    final imgCount = docs.where((d) => d.isImage).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Docs',
            count: '$totalCount',
            icon: Icons.folder_open_rounded,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'PDFs',
            count: '$pdfCount',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Images',
            count: '$imgCount',
            icon: Icons.image_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 21,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
