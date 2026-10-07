import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../domain/entities/document_entity.dart';
import '../../data/services/document_file_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final DocumentEntity document;
  final DocumentFileService fileService;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    required this.fileService,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  Future<void> _checkLocalCache() async {
    if (kIsWeb) return;

    // 1. Check if document already has a valid local filePath
    if (widget.document.filePath != null && widget.document.filePath!.isNotEmpty) {
      final f = File(widget.document.filePath!);
      if (await f.exists()) {
        if (mounted) {
          setState(() {
            _localFilePath = f.path;
            _isCached = true;
          });
        }
        return;
      }
    }

    // 2. Check if file is in dedicated downloads cache
    final cached = await widget.fileService.getCachedFile(
      docId: widget.document.id,
      fileName: widget.document.fileName,
      category: widget.document.category,
    );

    if (cached != null && await cached.exists()) {
      if (mounted) {
        setState(() {
          _localFilePath = cached.path;
          _isCached = true;
        });
      }
    }
  }

  Future<bool> _downloadFile({bool showSuccessSnackBar = true}) async {
    final url = widget.document.fileUrl;
    if ((url == null || url.isEmpty) && _localFilePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No download URL available for this document')),
        );
      }
      return false;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    if (kIsWeb) {
      try {
        if (url != null && url.isNotEmpty) {
          final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);
          try {
            final response = await widget.fileService.dio.get<List<int>>(
              resolvedUrl,
              options: Options(responseType: ResponseType.bytes),
              onReceiveProgress: (received, total) {
                if (total > 0 && mounted) {
                  setState(() {
                    _downloadProgress = received / total;
                  });
                }
              },
            );

            if (response.data != null) {
              triggerWebDownload(
                url: resolvedUrl,
                fileName: widget.document.fileName,
                bytes: Uint8List.fromList(response.data!),
              );
            } else {
              triggerWebDownload(
                url: resolvedUrl,
                fileName: widget.document.fileName,
              );
            }
          } catch (_) {
            triggerWebDownload(
              url: resolvedUrl,
              fileName: widget.document.fileName,
            );
          }

          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isCached = true;
            });

            if (showSuccessSnackBar) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Document "${widget.document.fileName}" downloaded!'),
                  backgroundColor: context.familyTheme.success,
                ),
              );
            }
          }
          return true;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e')),
          );
        }
        return false;
      }
      return false;
    }

    try {
      if (url != null && url.isNotEmpty) {
        final downloaded = await widget.fileService.downloadDocument(
          url: url,
          docId: widget.document.id,
          fileName: widget.document.fileName,
          category: widget.document.category,
          onProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _localFilePath = downloaded.path;
            _isCached = true;
            _isDownloading = false;
          });

          if (showSuccessSnackBar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Document downloaded to dedicated SangamVault/Downloads folder!',
                ),
                backgroundColor: context.familyTheme.success,
                action: SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: _openInSystemApp,
                ),
              ),
            );
          }
          return true;
        }
      } else if (_localFilePath != null) {
        setState(() => _isDownloading = false);
        return true;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        String errorMessage = 'Download failed';
        if (e is DioException) {
          if (e.response?.statusCode != null) {
            errorMessage = 'Download failed (Server returned HTTP ${e.response?.statusCode})';
          } else if (e.message != null && e.message!.isNotEmpty) {
            errorMessage = 'Download failed: ${e.message}';
          }
        } else {
          errorMessage = 'Download failed: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return false;
    }
    return false;
  }

  Future<void> _openInSystemApp() async {
    if (kIsWeb) {
      final url = widget.document.fileUrl;
      if (url != null && url.isNotEmpty) {
        final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);
        openInNewTabWeb(resolvedUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No URL available to open this document')),
        );
      }
      return;
    }

    var path = _localFilePath ?? widget.document.filePath ?? '';
    if (path.isEmpty || !await File(path).exists()) {
      // Need to download first, then proceed to open directly
      final success = await _downloadFile(showSuccessSnackBar: false);
      if (!success) return;
      path = _localFilePath ?? '';
      if (path.isEmpty || !await File(path).exists()) return;
    }

    try {
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.type == ResultType.noAppToOpen
                  ? 'No app found on your device to open ${widget.document.fileExtension.toUpperCase()} files'
                  : 'Could not open file: ${res.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareFile() async {
    if (kIsWeb) {
      final url = widget.document.fileUrl;
      if (url != null && url.isNotEmpty) {
        final resolvedUrl = ApiEndpoints.resolveDocumentUrl(url);
        await Clipboard.setData(ClipboardData(text: resolvedUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Document link copied to clipboard!'),
                ],
              ),
              backgroundColor: context.familyTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No link available to share')),
          );
        }
      }
      return;
    }

    final path = _localFilePath ?? widget.document.filePath ?? '';
    if (path.isNotEmpty && await File(path).exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, name: widget.document.fileName)],
          text: 'Sangam Document: ${widget.document.name}',
        ),
      );
    } else if (widget.document.fileUrl != null) {
      await SharePlus.instance.share(
        ShareParams(
          uri: Uri.parse(widget.document.fileUrl!),
        ),
      );
    } else {
      await _downloadFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final doc = widget.document;
    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(doc.uploadedAt);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant backdrop for viewer
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              doc.category,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: _isCached ? Colors.greenAccent : Colors.white,
              ),
              tooltip: _isCached ? 'Downloaded' : 'Download to device',
              onPressed: _downloadFile,
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _shareFile,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: kIsWeb ? 'Open in new tab' : 'Open with app',
            onPressed: _openInSystemApp,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Preview Area
          Expanded(
            child: Center(
              child: _buildPreviewBody(),
            ),
          ),

          // Bottom Info Sheet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.name,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isCached
                              ? Colors.green.withValues(alpha: 0.15)
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCached
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_outlined,
                              size: 13,
                              color: _isCached ? Colors.green : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isCached ? 'CACHED' : 'ON SERVER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isCached ? Colors.green : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (doc.description != null && doc.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      doc.description!,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetaChip(
                        Icons.insert_drive_file_outlined,
                        doc.fileExtension.toUpperCase(),
                        context,
                      ),
                      const SizedBox(width: 8),
                      _buildMetaChip(
                        Icons.data_usage_rounded,
                        doc.formattedFileSize,
                        context,
                      ),
                      const SizedBox(width: 8),
                      _buildMetaChip(
                        Icons.access_time_rounded,
                        formattedDate,
                        context,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: Text(_isCached ? 'Re-Download' : 'Download File'),
                          onPressed: _downloadFile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(kIsWeb ? 'Open in New Tab' : 'Open Viewer'),
                          onPressed: _openInSystemApp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody() {
    // 1. If Image
    if (widget.document.isImage) {
      if (!kIsWeb && _localFilePath != null && File(_localFilePath!).existsSync()) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.file(
            File(_localFilePath!),
            fit: BoxFit.contain,
          ),
        );
      } else if (widget.document.fileUrl != null &&
          widget.document.fileUrl!.isNotEmpty) {
        final resolvedUrl =
            ApiEndpoints.resolveDocumentUrl(widget.document.fileUrl!);
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.network(
            resolvedUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, _, _) => _buildPlaceholderCard(),
          ),
        );
      }
    }

    // 2. If PDF or fallback
    return _buildPlaceholderCard();
  }

  Widget _buildPlaceholderCard() {
    final doc = widget.document;
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: doc.isPdf
                  ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                  : const Color(0xFF2563EB).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              doc.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              color: doc.isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            doc.fileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${doc.formattedFileSize} • ${doc.category}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(kIsWeb ? 'Open in Browser' : 'Open Document'),
                onPressed: _openInSystemApp,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
                onPressed: _downloadFile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              fontSize: 11,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
