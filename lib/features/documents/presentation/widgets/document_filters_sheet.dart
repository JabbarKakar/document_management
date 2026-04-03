import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../domain/vault_document_filters.dart';
import '../providers/document_list_provider.dart';

/// Modal bottom sheet: category, file type, and expiry in a compact form.
///
/// Re-injects [DocumentListProvider] and [CategoryListProvider] because modal
/// routes are not descendants of the home route’s [MultiProvider].
Future<void> showDocumentFiltersSheet(BuildContext context) {
  final documents = context.read<DocumentListProvider>();
  final categories = context.read<CategoryListProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => MultiProvider(
      providers: [
        ChangeNotifierProvider<DocumentListProvider>.value(value: documents),
        ChangeNotifierProvider<CategoryListProvider>.value(value: categories),
      ],
      child: const _DocumentFiltersSheetBody(),
    ),
  );
}

class _DocumentFiltersSheetBody extends StatefulWidget {
  const _DocumentFiltersSheetBody();

  @override
  State<_DocumentFiltersSheetBody> createState() =>
      _DocumentFiltersSheetBodyState();
}

class _DocumentFiltersSheetBodyState extends State<_DocumentFiltersSheetBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final docs = context.read<DocumentListProvider>();
      final cats = context.read<CategoryListProvider>().categories;
      final id = docs.categoryFilter;
      if (id != null && !cats.any((c) => c.id == id)) {
        docs.setCategoryFilter(null);
      }
    });
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Consumer2<DocumentListProvider, CategoryListProvider>(
      builder: (context, docs, categories, _) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: docs.hasStructuredFilters
                        ? () => docs.clearStructuredFilters()
                        : null,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Category, file type, and expiry. Your search text is unchanged.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int?>(
                value: _validCategoryValue(docs.categoryFilter, categories),
                isExpanded: true,
                decoration: _fieldDecoration(context, 'Category'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...categories.categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (id) => docs.setCategoryFilter(id),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VaultFileTypeFilter>(
                value: docs.fileTypeFilter,
                isExpanded: true,
                decoration: _fieldDecoration(context, 'File type'),
                items: [
                  for (final f in VaultFileTypeFilter.values)
                    DropdownMenuItem<VaultFileTypeFilter>(
                      value: f,
                      child: Text(f.chipLabel),
                    ),
                ],
                onChanged: (f) {
                  if (f != null) docs.setFileTypeFilter(f);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VaultExpiryFilter>(
                value: docs.expiryFilter,
                isExpanded: true,
                decoration: _fieldDecoration(context, 'Expiry'),
                items: [
                  for (final e in VaultExpiryFilter.values)
                    DropdownMenuItem<VaultExpiryFilter>(
                      value: e,
                      child: Text(e.chipLabel),
                    ),
                ],
                onChanged: (e) {
                  if (e != null) docs.setExpiryFilter(e);
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Avoid DropdownButton assertion if the stored category id no longer exists.
  static int? _validCategoryValue(
    int? filter,
    CategoryListProvider categories,
  ) {
    if (filter == null) return null;
    final exists = categories.categories.any((c) => c.id == filter);
    return exists ? filter : null;
  }
}
