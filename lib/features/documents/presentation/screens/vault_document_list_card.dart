import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/expiry_calendar.dart';

/// Serializes PDF page renders — Android backend does not allow parallel renders.
class _PdfThumbnailLock {
  static Future<void> _chain = Future.value();

  static Future<T> run<T>(Future<T> Function() fn) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await fn());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}

double _logicalThumbSize(BuildContext context) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  // ~56dp leading; cap decode cost on very high DPR
  final base = 56.0 * dpr.clamp(1, 3);
  return base;
}

bool _isPdfDocument(VaultDocument doc) {
  return doc.fileType == VaultDocumentFileType.pdf ||
      doc.filePath.toLowerCase().endsWith('.pdf');
}

Future<Uint8List?> _renderPdfFirstPageThumb(Uint8List pdfBytes) async {
  PdfDocument? doc;
  PdfPage? page;
  try {
    doc = await PdfDocument.openData(pdfBytes);
    if (doc.pagesCount < 1) return null;
    page = await doc.getPage(1);
    const targetW = 200.0;
    final targetH = targetW * page.height / page.width;
    final rendered = await page.render(
      width: targetW,
      height: targetH,
      format: PdfPageImageFormat.jpeg,
      quality: 82,
    );
    return rendered?.bytes;
  } catch (_) {
    return null;
  } finally {
    try {
      await page?.close();
    } catch (_) {}
    try {
      await doc?.close();
    } catch (_) {}
  }
}

IconData _fallbackIcon(VaultDocumentFileType t) {
  return switch (t) {
    VaultDocumentFileType.image => Icons.image_outlined,
    VaultDocumentFileType.pdf => Icons.picture_as_pdf_outlined,
    VaultDocumentFileType.other => Icons.insert_drive_file_outlined,
  };
}

/// Leading thumbnail: decrypted image, first PDF page render, or type icon.
class VaultDocumentThumbnail extends StatefulWidget {
  const VaultDocumentThumbnail({
    super.key,
    required this.document,
  });

  final VaultDocument document;

  @override
  State<VaultDocumentThumbnail> createState() => _VaultDocumentThumbnailState();
}

class _VaultDocumentThumbnailState extends State<VaultDocumentThumbnail> {
  static const double _diameter = 56;

  bool _loading = true;
  Uint8List? _thumbBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final storage = context.read<EncryptedFileStorageService>();
    final logical = _logicalThumbSize(context).round();

    try {
      final bytes =
          await storage.readDecryptedBytes(widget.document.filePath);
      if (!mounted) return;

      if (_isPdfDocument(widget.document)) {
        final jpeg = await _PdfThumbnailLock.run(
          () => _renderPdfFirstPageThumb(bytes),
        );
        if (!mounted) return;
        if (jpeg != null && jpeg.isNotEmpty) {
          setState(() {
            _thumbBytes = jpeg;
            _loading = false;
          });
          return;
        }
      } else {
        ui.Codec? codec;
        try {
          codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: logical,
          );
          final frame = await codec.getNextFrame();
          frame.image.dispose();
          if (!mounted) return;
          setState(() {
            _thumbBytes = bytes;
            _loading = false;
          });
          return;
        } catch (_) {
        } finally {
          codec?.dispose();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: ClipOval(
        child: Material(
          color: scheme.primaryContainer.withValues(alpha: 0.9),
          child: _buildInner(scheme),
        ),
      ),
    );
  }

  Widget _buildInner(ColorScheme scheme) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final bytes = _thumbBytes;
    if (bytes != null && bytes.isNotEmpty) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final cacheW = (_diameter * dpr).round();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: _diameter,
        height: _diameter,
        gaplessPlayback: true,
        cacheWidth: cacheW,
        errorBuilder: (_, _, _) => _iconFallback(scheme),
      );
    }

    return _iconFallback(scheme);
  }

  Widget _iconFallback(ColorScheme scheme) {
    return Icon(
      _fallbackIcon(widget.document.fileType),
      color: scheme.onPrimaryContainer,
      size: 26,
    );
  }
}

/// List card for a vault document: open viewer, edit metadata, delete.
class VaultDocumentListCard extends StatelessWidget {
  const VaultDocumentListCard({
    super.key,
    required this.document,
    required this.onOpen,
    this.onDetails,
    required this.onEdit,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelected,
    this.onLongPress,
  });

  final VaultDocument document;
  final VoidCallback onOpen;
  final VoidCallback? onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;

  static String _formatExpiry(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$mo-$day';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expiry = document.expiryDate;
    final expiryUrgent = expiry != null && isExpiryUrgentRed(expiry);
    final expiryColor = expiryUrgent ? scheme.error : scheme.onSurfaceVariant;
    final expiryIconColor =
        expiryUrgent ? scheme.error : scheme.onSurfaceVariant.withValues(alpha: 0.9);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        leading: VaultDocumentThumbnail(
          key: ValueKey<int>(document.id),
          document: document,
        ),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.fileType.name.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: 0.08,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (expiry != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 14,
                    color: expiryIconColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expires ${_formatExpiry(expiry)}',
                      style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.04,
                        color: expiryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: expiry != null,
        trailing: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelected?.call(),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                    ),
                    tooltip: 'Details',
                    onPressed: onDetails,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: scheme.primary.withValues(alpha: 0.9),
                    ),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.error.withValues(alpha: 0.85),
                    ),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
      ),
    );
  }
}
