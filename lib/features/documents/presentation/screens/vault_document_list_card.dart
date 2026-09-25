import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/document_thumbnail_cache_service.dart';
import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/theme/app_tokens.dart';
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

Future<Uint8List?> _renderImageThumbBytes(
  Uint8List imageBytes, {
  required int targetWidth,
}) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
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
    this.size = 56,
    this.height,
    this.expandWidth = false,
    this.borderRadius = 12,
  });

  final VaultDocument document;
  final double size;
  final double? height;
  final bool expandWidth;
  final double borderRadius;

  @override
  State<VaultDocumentThumbnail> createState() => _VaultDocumentThumbnailState();
}

class _VaultDocumentThumbnailState extends State<VaultDocumentThumbnail> {
  bool _loading = true;
  Uint8List? _thumbBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant VaultDocumentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.filePath != widget.document.filePath ||
        oldWidget.document.fileType != widget.document.fileType) {
      _thumbBytes = null;
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final storage = context.read<EncryptedFileStorageService>();
    final cache = context.read<DocumentThumbnailCacheService>();
    final logical = _logicalThumbSize(context).round();
    final cacheKey = '${widget.document.id}|${widget.document.filePath}';

    final thumb = await cache.getOrLoad(
      key: cacheKey,
      loader: () async {
        try {
          final bytes = await storage.readDecryptedBytes(
            widget.document.filePath,
          );
          if (_isPdfDocument(widget.document)) {
            return await _PdfThumbnailLock.run(
              () => _renderPdfFirstPageThumb(bytes),
            );
          }
          final pngThumb = await _renderImageThumbBytes(
            bytes,
            targetWidth: logical,
          );
          return pngThumb ?? bytes;
        } catch (_) {
          return null;
        }
      },
    );

    if (!mounted) return;
    if (thumb != null && thumb.isNotEmpty) {
      setState(() {
        _thumbBytes = thumb;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbHeight = widget.height ?? widget.size;

    return SizedBox(
      width: widget.expandWidth ? double.infinity : widget.size,
      height: thumbHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: ColoredBox(
          color: scheme.primaryContainer,
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
      final cacheW = ((widget.height ?? widget.size) * dpr).round();
      final image = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: widget.expandWidth ? null : widget.size,
        height: widget.expandWidth ? null : (widget.height ?? widget.size),
        gaplessPlayback: true,
        cacheWidth: cacheW,
        errorBuilder: (_, _, _) => _iconFallback(scheme),
      );
      if (widget.expandWidth) return SizedBox.expand(child: image);
      return image;
    }

    return Center(child: _iconFallback(scheme));
  }

  Widget _iconFallback(ColorScheme scheme) {
    return Icon(
      _fallbackIcon(widget.document.fileType),
      color: scheme.onPrimaryContainer,
      size: 26,
    );
  }
}

enum VaultDocumentCardLayout { list, grid }

/// List or grid card for a vault document: open viewer, edit metadata, delete.
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
    this.categoryName,
    this.layout = VaultDocumentCardLayout.list,
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
  final String? categoryName;
  final VaultDocumentCardLayout layout;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  static String typeLabel(VaultDocumentFileType type) => switch (type) {
    VaultDocumentFileType.image => 'Image',
    VaultDocumentFileType.pdf => 'PDF',
    VaultDocumentFileType.other => 'File',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = AppRadius.cardBorder;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? null : AppColors.cardShadow(scheme.brightness),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: layout == VaultDocumentCardLayout.grid
              ? _gridBody(context)
              : _listBody(context),
        ),
      ),
    );
  }

  Widget _listBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          VaultDocumentThumbnail(
            key: ValueKey<String>('${document.id}|${document.filePath}'),
            document: document,
            borderRadius: AppRadius.chip,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _metaColumn(context)),
          _trailing(context),
        ],
      ),
    );
  }

  Widget _gridBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            VaultDocumentThumbnail(
              key: ValueKey<String>('${document.id}|${document.filePath}'),
              document: document,
              height: 112,
              expandWidth: true,
              borderRadius: 0,
            ),
            if (selectionMode)
              Positioned(top: 0, right: 0, child: _selectionBox()),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xxs,
              AppSpacing.xxs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaColumn(context),
                const Spacer(),
                if (!selectionMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _actionsMenu(context),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaColumn(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expiry = document.expiryDate;
    final expiryUrgent = expiry != null && isExpiryUrgentRed(expiry);
    final expiryColor = expiryUrgent
        ? scheme.error
        : AppColors.warning(scheme.brightness);
    final meta = textTheme.labelMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TypeBadge(label: typeLabel(document.fileType)),
            if (categoryName != null)
              Text(
                categoryName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: meta,
              ),
            Text(formatDate(document.createdAt), style: meta),
          ],
        ),
        if (expiry != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: expiryColor),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  'Expires ${formatDate(expiry)}',
                  style: textTheme.labelMedium?.copyWith(color: expiryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _trailing(BuildContext context) {
    if (selectionMode) return _selectionBox();
    return _actionsMenu(context);
  }

  Widget _selectionBox() {
    return Checkbox(
      value: selected,
      onChanged: (_) => onToggleSelected?.call(),
    );
  }

  Widget _actionsMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_CardAction>(
      tooltip: 'Actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: (action) {
        switch (action) {
          case _CardAction.details:
            onDetails?.call();
          case _CardAction.edit:
            onEdit();
          case _CardAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<_CardAction>(
          value: _CardAction.details,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Details'),
          ),
        ),
        const PopupMenuItem<_CardAction>(
          value: _CardAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem<_CardAction>(
          value: _CardAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
            title: Text('Delete', style: TextStyle(color: scheme.error)),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onPrimaryContainer,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

enum _CardAction { details, edit, delete }
