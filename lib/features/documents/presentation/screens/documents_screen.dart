import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import '../widgets/document_card.dart';
import '../widgets/add_category_bottom_sheet.dart';
import '../widgets/manage_categories_bottom_sheet.dart';
import '../widgets/upload_document_sheet.dart';

class DocumentsScreen extends StatefulWidget {
  final SangamUserEntity user;

  const DocumentsScreen({super.key, required this.user});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _searchController = TextEditingController();
  bool _showCategoriesGrid = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<DocumentBloc>().add(const FetchDocumentsRequested());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            tooltip: 'Refresh Documents from Server',
            onPressed: () {
              final state = context.read<DocumentBloc>().state;
              final cat =
                  state is DocumentLoaded ? state.selectedCategory : 'All';
              final q = state is DocumentLoaded ? state.searchQuery : '';
              context.read<DocumentBloc>().add(
                    RefreshDocumentsRequested(category: cat, searchQuery: q),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking for updated documents from server...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
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

          final docs = loaded.filteredDocuments;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(
                    RefreshDocumentsRequested(
                      category: loaded.selectedCategory,
                      searchQuery: loaded.searchQuery,
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
                        // Stats Overview Banner
                        _buildStatsRow(context, loaded),
                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            context
                                .read<DocumentBloc>()
                                .add(SearchDocumentsChanged(val));
                          },
                          decoration: InputDecoration(
                            hintText: 'Search documents by name, category...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<DocumentBloc>()
                                          .add(const SearchDocumentsChanged(''));
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
                        // Categories Section (Grid by default, with toggle)
                        _buildCategoriesSection(context, loaded),
                        const SizedBox(height: 16),

                        // Section Heading with Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              docs.isEmpty
                                  ? 'Documents'
                                  : 'Documents (${docs.length})',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (loaded.selectedCategory != 'All' ||
                                loaded.searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<DocumentBloc>()
                                      .add(const FilterCategorySelected('All'));
                                  context
                                      .read<DocumentBloc>()
                                      .add(const SearchDocumentsChanged(''));
                                },
                                child: const Text('Reset filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Documents List or Empty State
                if (docs.isEmpty)
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
                                color: colors.primaryContainer
                                    .withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_open_rounded,
                                size: 42,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loaded.searchQuery.isNotEmpty
                                  ? 'No documents matching "${loaded.searchQuery}"'
                                  : 'No documents found in "${loaded.selectedCategory}"',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload property deeds, agreements, or member identity proofs (PDF / Images up to 5MB).',
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: const Text('Upload Document'),
                              onPressed: () => _showUploadSheet(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
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
                        childCount: docs.length,
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

  Widget _buildStatsRow(BuildContext context, DocumentLoaded state) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Files',
            count: '${state.totalDocsCount}',
            icon: Icons.folder_rounded,
            color: colors.primary,
            bgColor: colors.primaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Categories',
            count: '${state.categoriesCount}',
            icon: Icons.category_rounded,
            color: colors.secondary,
            bgColor: colors.secondaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Storage Used',
            count: state.formattedTotalSize,
            icon: Icons.storage_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context, DocumentLoaded state) {
    final colors = context.colors;
    final text = context.text;
    final categories = state.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with count and view toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Categories',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${categories.length}',
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (state.selectedCategory != 'All')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        context
                            .read<DocumentBloc>()
                            .add(const FilterCategorySelected('All'));
                      },
                      child: const Text('Show all'),
                    ),
                  ),
                // Toggle between Grid View & Compact Horizontal View
                IconButton(
                  icon: Icon(
                    _showCategoriesGrid
                        ? Icons.view_stream_rounded
                        : Icons.grid_view_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: _showCategoriesGrid
                      ? 'Switch to compact row'
                      : 'Show categories as grid',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _showCategoriesGrid = !_showCategoriesGrid;
                    });
                  },
                ),
                if (widget.user.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Manage Categories',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showManageCategoriesSheet(context),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_showCategoriesGrid)
          _buildCategoryGrid(context, state)
        else
          _buildCategoryChips(context, state),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, DocumentLoaded state) {
    final colors = context.colors;
    final text = context.text;
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.38,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // 1. "All Documents" Card
        if (index == 0) {
          final isSelected = state.selectedCategory == 'All';
          final count = state.allDocuments.length;

          return _CategoryGridCard(
            title: 'All Documents',
            subtitle: '$count ${count == 1 ? 'file' : 'files'}',
            icon: Icons.grid_view_rounded,
            color: colors.primary,
            isSelected: isSelected,
            onTap: () {
              context
                  .read<DocumentBloc>()
                  .add(const FilterCategorySelected('All'));
            },
          );
        }

        // 2. "+ Add Category" Card for Admin (at the end)
        if (hasAddCard && index == totalItems - 1) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => AddCategoryBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Category',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create new folder',
                        style: text.bodySmall?.copyWith(
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
        final isSelected =
            state.selectedCategory.toLowerCase() == cat.name.toLowerCase();
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
          isSelected: isSelected,
          onTap: () {
            if (isSelected) {
              // Tapping currently selected category clears selection
              context
                  .read<DocumentBloc>()
                  .add(const FilterCategorySelected('All'));
            } else {
              context
                  .read<DocumentBloc>()
                  .add(FilterCategorySelected(cat.name));
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context, DocumentLoaded state) {
    final colors = context.colors;
    final text = context.text;
    final categories = state.categories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" Chip
          FilterChip(
            selected: state.selectedCategory == 'All',
            showCheckmark: false,
            avatar: Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: state.selectedCategory == 'All'
                  ? colors.onPrimary
                  : colors.onSurfaceVariant,
            ),
            label: Text('All (${state.allDocuments.length})'),
            labelStyle: text.bodySmall?.copyWith(
              fontWeight: state.selectedCategory == 'All'
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: state.selectedCategory == 'All'
                  ? colors.onPrimary
                  : colors.onSurface,
            ),
            selectedColor: colors.primary,
            backgroundColor:
                colors.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(
              color: state.selectedCategory == 'All'
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.6),
            ),
            onSelected: (_) {
              context
                  .read<DocumentBloc>()
                  .add(const FilterCategorySelected('All'));
            },
          ),
          const SizedBox(width: 8),

          // Dynamic Category Chips
          ...categories.map((cat) {
            final isSelected =
                state.selectedCategory.toLowerCase() == cat.name.toLowerCase();
            final count = state.allDocuments
                .where((d) => d.category.toLowerCase() == cat.name.toLowerCase())
                .length;
            final icon = _resolveCategoryIcon(cat.iconName);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
                label: Text('${cat.name} ($count)'),
                labelStyle: text.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.onPrimary : colors.onSurface,
                ),
                selectedColor: colors.primary,
                backgroundColor:
                    colors.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isSelected
                      ? colors.primary
                      : colors.outlineVariant.withValues(alpha: 0.6),
                ),
                onSelected: (_) {
                  context
                      .read<DocumentBloc>()
                      .add(FilterCategorySelected(cat.name));
                },
              ),
            );
          }),

          // Admin Add Category Chip
          if (widget.user.isAdmin)
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 16, color: colors.primary),
              label: Text(
                'Category',
                style: text.bodySmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: colors.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
              onPressed: () => AddCategoryBottomSheet.show(context),
            ),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : colors.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : colors.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.22)
                          : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 19,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? color : colors.onSurface,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
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
    );
  }
}
