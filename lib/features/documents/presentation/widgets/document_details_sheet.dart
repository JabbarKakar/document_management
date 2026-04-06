import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../domain/entities/vault_document.dart';

Future<void> showDocumentDetailsSheet(
  BuildContext context, {
  required VaultDocument document,
  required VoidCallback onOpen,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onExport,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ChangeNotifierProvider.value(
      value: context.read<CategoryListProvider>(),
      child: _DocumentDetailsSheet(
        document: document,
        onOpen: onOpen,
        onEdit: onEdit,
        onDelete: onDelete,
        onExport: onExport,
      ),
    ),
  );
}

class _DocumentDetailsSheet extends StatelessWidget {
  const _DocumentDetailsSheet({
    required this.document,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final VaultDocument document;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  static String _fmtDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _typeLabel(VaultDocumentFileType t) {
    return switch (t) {
      VaultDocumentFileType.image => 'IMAGE',
      VaultDocumentFileType.pdf => 'PDF',
      VaultDocumentFileType.other => 'FILE',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cats = context.watch<CategoryListProvider>().categories;
    String? categoryName;
    if (document.categoryId == null) {
      categoryName = 'No category';
    } else {
      for (final c in cats) {
        if (c.id == document.categoryId) {
          categoryName = c.name;
          break;
        }
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.title,
              style: textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_typeLabel(document.fileType))),
                Chip(label: Text(categoryName ?? 'Category removed')),
              ],
            ),
            const SizedBox(height: 16),
            _MetaRow(
              label: 'Created',
              value: _fmtDate(document.createdAt),
              icon: Icons.calendar_month_outlined,
            ),
            _MetaRow(
              label: 'Expiry',
              value: document.expiryDate == null
                  ? 'No expiry date'
                  : _fmtDate(document.expiryDate!),
              icon: Icons.event_rounded,
            ),
            const SizedBox(height: 10),
            Text(
              'Notes',
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (document.notes ?? '').trim().isEmpty
                    ? 'No notes'
                    : document.notes!,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpen();
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onExport();
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Export'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  style: FilledButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
