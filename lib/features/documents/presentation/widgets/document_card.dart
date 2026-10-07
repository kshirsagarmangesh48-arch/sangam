import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../data/services/document_file_service.dart';
import '../../domain/entities/document_entity.dart';
import '../screens/document_viewer_screen.dart';

class DocumentCard extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool canDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onDelete,
    this.onTap,
    this.canDelete = true,
  });

  /// Opens the document directly into the device's system viewer (PDF viewer, gallery, etc.)
  /// Automatically downloads first if not yet cached on the device.
  static Future<void> openDirectly(
    BuildContext context,
    DocumentEntity document,
  ) async {
    // 1. If it's an image, open instantly in the in-app interactive zoomable viewer
    if (document.isImage) {
      final fileService = context.read<DocumentFileService>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            document: document,
            fileService: fileService,
          ),
        ),
      );
      return;
    }

    if (kIsWeb) {
      final url = document.fileUrl;
      if (url != null && url.isNotEmpty) {
        final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);
        openInNewTabWeb(resolvedUrl);
      } else {
        final fileService = context.read<DocumentFileService>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(
              document: document,
              fileService: fileService,
            ),
          ),
        );
      }
      return;
    }

    final fileService = context.read<DocumentFileService>();

    // 1. Check if already present or cached on device
    String? localPath;
    if (document.filePath != null && document.filePath!.isNotEmpty) {
      final file = File(document.filePath!);
      if (await file.exists()) {
        localPath = file.path;
      }
    }

    if (localPath == null) {
      final cached = await fileService.getCachedFile(
        docId: document.id,
        fileName: document.fileName,
        category: document.category,
      );
      if (cached != null && await cached.exists()) {
        localPath = cached.path;
      }
    }

    // If available locally, open immediately without showing download dialog
    if (localPath != null) {
      try {
        final result = await OpenFilex.open(localPath);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.type == ResultType.noAppToOpen
                    ? 'No app found on device to open ${document.fileExtension.toUpperCase()} files'
                    : 'Could not open file: ${result.message}',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: $e')),
          );
        }
      }
      return;
    }

    // 2. Download from remote URL then open directly
    final url = document.fileUrl;
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No download URL available for this document')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Show opening indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opening document...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final downloaded = await fileService.downloadDocument(
        url: url,
        docId: document.id,
        fileName: document.fileName,
        category: document.category,
      );

      // Dismiss dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final result = await OpenFilex.open(downloaded.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.type == ResultType.noAppToOpen
                  ? 'No app found on device to open ${document.fileExtension.toUpperCase()} files'
                  : 'Could not open file: ${result.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open document: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(BuildContext context) async {
    final url = document.fileUrl;
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No download URL available for this document')),
        );
      }
      return;
    }

    final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);

    if (kIsWeb) {
      try {
        final fileService = context.read<DocumentFileService>();
        final response = await fileService.dio.get<List<int>>(
          resolvedUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          triggerWebDownload(
            url: resolvedUrl,
            fileName: document.fileName,
            bytes: Uint8List.fromList(response.data!),
          );
        } else {
          triggerWebDownload(
            url: resolvedUrl,
            fileName: document.fileName,
          );
        }
      } catch (_) {
        triggerWebDownload(
          url: resolvedUrl,
          fileName: document.fileName,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "${document.fileName}"!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      return;
    }

    try {
      final fileService = context.read<DocumentFileService>();
      await fileService.downloadDocument(
        url: url,
        docId: document.id,
        fileName: document.fileName,
        category: document.category,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${document.fileName}" to SangamVault/Downloads!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    if (kIsWeb) {
      final url = document.fileUrl;
      if (url != null && url.isNotEmpty) {
        final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);
        await Clipboard.setData(ClipboardData(text: resolvedUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Document link copied to clipboard!'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No link available to share')),
          );
        }
      }
      return;
    }

    final fileService = context.read<DocumentFileService>();
    String? localPath;
    if (document.filePath != null && document.filePath!.isNotEmpty) {
      final file = File(document.filePath!);
      if (await file.exists()) {
        localPath = file.path;
      }
    }

    if (localPath == null) {
      final cached = await fileService.getCachedFile(
        docId: document.id,
        fileName: document.fileName,
        category: document.category,
      );
      if (cached != null && await cached.exists()) {
        localPath = cached.path;
      }
    }

    if (localPath != null && await File(localPath).exists()) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(localPath, name: document.fileName)],
            text: 'Document: ${document.name}',
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing document: $e')),
          );
        }
      }
    } else if (document.fileUrl != null && document.fileUrl!.isNotEmpty) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            uri: Uri.parse(document.fileUrl!),
            text: 'Document: ${document.name}',
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing document: $e')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file or URL available to share')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    if (document.isPdf) return const Color(0xFFDC2626); // Crimson red
    if (document.isImage) return const Color(0xFF7C3AED); // Royal violet
    return const Color(0xFF1E3A8A); // Deep blue
  }

  IconData _getFileIcon() {
    if (document.isPdf) return Icons.picture_as_pdf_rounded;
    if (document.isImage) return Icons.image_rounded;
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final badgeColor = _getBadgeColor();
    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(document.uploadedAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => openDirectly(context, document),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Icon Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getFileIcon(),
                        color: badgeColor,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              document.formattedFileSize,
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: text.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              document.fileExtension.toUpperCase(),
                              style: text.bodySmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'open') openDirectly(context, document);
                      if (value == 'preview') {
                        final fileService = context.read<DocumentFileService>();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentViewerScreen(
                              document: document,
                              fileService: fileService,
                            ),
                          ),
                        );
                      }
                      if (value == 'download') _downloadFile(context);
                      if (value == 'share') _shareFile(context);
                      if (value == 'delete') _confirmDelete(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Open Document'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Preview & Info'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Download Document'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Share File'),
                          ],
                        ),
                      ),
                      if (canDelete) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: colors.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: colors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              if (document.description != null &&
                  document.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  document.description!,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom Tags & Metadata Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      document.category,
                      style: text.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  // Uploaded date
                  Text(
                    formattedDate,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
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
