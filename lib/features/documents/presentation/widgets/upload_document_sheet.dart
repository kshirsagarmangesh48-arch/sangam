import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/document_category_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import 'add_category_bottom_sheet.dart';
import 'manage_categories_bottom_sheet.dart';

class UploadDocumentSheet extends StatefulWidget {
  final SangamUserEntity user;
  final String? initialCategory;

  const UploadDocumentSheet({
    super.key,
    required this.user,
    this.initialCategory,
  });

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  PlatformFile? _selectedFile;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }
  int _selectedFileSize = 0;
  Uint8List? _selectedFileBytes;
  bool _isSubmitting = false;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = [
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'webp',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (pickedFiles.isNotEmpty) {
        final file = pickedFiles.first;
        final ext = (file.extension ?? '').toLowerCase();

        // 1. Validate PDF or Image only
        if (!_allowedExtensions.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid file type. Only PDF and Images (JPG, PNG, WebP) are allowed.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // 2. Validate Max size 5MB
        int size = file.lengthSync() ?? 0;
        if (size == 0) {
          size = (await file.length()) ?? 0;
        }

        if (size > _maxFileSizeBytes) {
          final sizeMb = (size / (1024 * 1024)).toStringAsFixed(2);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File size ($sizeMb MB) exceeds the 5MB limit. Please select a smaller file.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        Uint8List? bytes;
        if (kIsWeb || file.path == null) {
          bytes = await file.readAsBytes();
        }

        setState(() {
          _selectedFile = file;
          _selectedFileSize = size;
          _selectedFileBytes = bytes;

          // Auto-fill document name from filename (without extension) if empty
          if (_nameController.text.trim().isEmpty) {
            final fileName = file.name;
            final lastDot = fileName.lastIndexOf('.');
            _nameController.text =
                lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _submit() {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF or Image document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFileSize > _maxFileSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected file exceeds 5MB limit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final docState = context.read<DocumentBloc>().state;
    List<DocumentCategoryEntity> categories = [];
    if (docState is DocumentLoaded) {
      categories = docState.categories;
    }

    final category = _selectedCategory ??
        (categories.isNotEmpty ? categories.first.name : 'Common Property');

    setState(() => _isSubmitting = true);

    context.read<DocumentBloc>().add(
          UploadDocumentRequested(
            name: _nameController.text.trim(),
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            category: category,
            filePath: _selectedFile!.path ?? '',
            fileBytes: _selectedFileBytes,
            fileName: _selectedFile!.name,
            fileSizeBytes: _selectedFileSize,
          ),
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading "${_nameController.text.trim()}" to server...'),
        backgroundColor: context.familyTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
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
                          Icons.cloud_upload_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Document',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'PDF and Images only • Max 5MB',
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

              // File Picker Box
              if (_selectedFile == null)
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.file_upload_outlined,
                            size: 32,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap to select PDF or Image',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Formats: PDF, JPG, PNG, WebP (Max 5MB)',
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          (_selectedFile!.extension?.toLowerCase() == 'pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatBytes(_selectedFileSize)} • ${_selectedFile!.extension?.toUpperCase()}',
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Change'),
                        onPressed: _pickFile,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // 1. Document Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Document Name *',
                  hintText: 'e.g. Sale Deed, Electricity Bill, Aadhaar Card',
                  prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter document name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // 2. Category Dropdown
              BlocBuilder<DocumentBloc, DocumentState>(
                builder: (context, state) {
                  final categories = state is DocumentLoaded
                      ? state.categories
                      : <DocumentCategoryEntity>[];

                  if (categories.isEmpty) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                              hintText: 'e.g. Property, Agreements, Tax',
                              prefixIcon: Icon(Icons.folder_outlined),
                            ),
                            onChanged: (val) {
                              _selectedCategory = val.trim();
                            },
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter category name';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (widget.user.isAdmin) ...[
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add Category',
                            onPressed: () async {
                              final newCat =
                                  await AddCategoryBottomSheet.show(context);
                              if (newCat != null && newCat.isNotEmpty) {
                                setState(() {
                                  _selectedCategory = newCat;
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    );
                  }

                  if (_selectedCategory == null ||
                      !categories.any((c) => c.name == _selectedCategory)) {
                    _selectedCategory = categories.first.name;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.folder_outlined),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.name,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (widget.user.isAdmin) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Add New Category',
                          onPressed: () async {
                            final newCat =
                                await AddCategoryBottomSheet.show(context);
                            if (newCat != null && newCat.isNotEmpty) {
                              setState(() {
                                _selectedCategory = newCat;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Manage Categories',
                          onPressed: () {
                            ManageCategoriesBottomSheet.show(
                              context,
                              isAdmin: widget.user.isAdmin,
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),

              // 3. Description (Optional)
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Valid till 2030, Registered at Satara office',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),

              const SizedBox(height: 24),

              // Upload & Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isSubmitting ? 'Uploading...' : 'Upload Document'),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
