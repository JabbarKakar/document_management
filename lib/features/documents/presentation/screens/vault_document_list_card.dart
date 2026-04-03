import 'package:flutter/material.dart';

import '../../domain/entities/vault_document.dart';

/// List card for a vault document: open viewer, edit metadata, delete.
class VaultDocumentListCard extends StatelessWidget {
  const VaultDocumentListCard({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final VaultDocument document;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static IconData iconForType(VaultDocumentFileType t) {
    return switch (t) {
      VaultDocumentFileType.image => Icons.image_outlined,
      VaultDocumentFileType.pdf => Icons.picture_as_pdf_outlined,
      VaultDocumentFileType.other => Icons.insert_drive_file_outlined,
    };
  }

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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.9),
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(iconForType(document.fileType)),
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
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Expires ${_formatExpiry(expiry)}',
                      style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.04,
                        color: scheme.onSurfaceVariant,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
