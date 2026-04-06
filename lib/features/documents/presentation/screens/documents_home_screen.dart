import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_controller.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/vault_document_sort.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_details_sheet.dart';
import '../widgets/document_filters_sheet.dart';
import 'document_viewer_screen.dart';
import 'edit_document_screen.dart';
import 'vault_document_list_card.dart';

class DocumentsHomeScreen extends StatefulWidget {
  const DocumentsHomeScreen({super.key});

  @override
  State<DocumentsHomeScreen> createState() => _DocumentsHomeScreenState();
}

class _DocumentsHomeScreenState extends State<DocumentsHomeScreen> {
  late final TextEditingController _searchController;
  final Set<int> _selectedIds = <int>{};
  bool _isExporting = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pushEditScreen(BuildContext context, VaultDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<DocumentListProvider>(),
            ),
            ChangeNotifierProvider.value(
              value: context.read<CategoryListProvider>(),
            ),
          ],
          child: EditDocumentScreen(existing: doc),
        ),
      ),
    );
  }

  void _openViewer(VaultDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Provider<EncryptedFileStorageService>.value(
          value: context.read<EncryptedFileStorageService>(),
          child: DocumentViewerScreen(document: doc),
        ),
      ),
    );
  }

  Future<bool> _confirmExportCount(int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(count == 1 ? 'Export document?' : 'Export $count documents?'),
        content: const Text(
          'Exported files are decrypted copies and will be saved unencrypted outside the vault.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _exportDocuments(List<VaultDocument> docs) async {
    if (docs.isEmpty || _isExporting) return;
    if (!await _confirmExportCount(docs.length)) return;
    if (!mounted) return;

    final exportService = context.read<DocumentExportService>();
    final storage = context.read<EncryptedFileStorageService>();
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          docs.length == 1
              ? 'Preparing export...'
              : 'Preparing ${docs.length} exports...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await exportService.exportDocumentsViaShare(
            documents: docs,
            storage: storage,
            message: docs.length == 1 ? docs.first.title.trim() : null,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            docs.length == 1
                ? 'Export sheet opened.'
                : 'Export sheet opened for ${docs.length} documents.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not export files. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _openDetailsSheet(VaultDocument doc) {
    showDocumentDetailsSheet(
      context,
      document: doc,
      onOpen: () => _openViewer(doc),
      onEdit: () => _pushEditScreen(context, doc),
      onDelete: () => context.read<DocumentListProvider>().deleteDocument(doc),
      onExport: () => _exportDocuments([doc]),
    );
  }

  Future<void> _clearAllListFilters() async {
    _searchController.clear();
    await context.read<DocumentListProvider>().clearAllListFilters();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) return;
    setState(() => _selectedIds.clear());
  }

  void _syncSelectionWithVisible(List<VaultDocument> visible) {
    if (_selectedIds.isEmpty) return;
    final visibleIds = visible.map((d) => d.id).toSet();
    if (_selectedIds.any((id) => !visibleIds.contains(id))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedIds.removeWhere((id) => !visibleIds.contains(id)));
      });
    }
  }

  List<VaultDocument> _selectedVisibleDocuments(List<VaultDocument> visible) {
    if (_selectedIds.isEmpty) return const [];
    return visible.where((d) => _selectedIds.contains(d.id)).toList();
  }

  void _selectAllVisible(List<VaultDocument> visible) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(visible.map((d) => d.id));
    });
  }

  Future<void> _confirmBatchDelete(List<VaultDocument> selected) async {
    if (selected.isEmpty) return;
    final count = selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count documents?'),
        content: const Text(
          'This permanently removes the selected encrypted files from your vault.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<DocumentListProvider>().deleteDocuments(selected);
    if (!mounted) return;
    _clearSelection();
  }

  Future<void> _openBatchCategorySheet(List<VaultDocument> selected) async {
    if (selected.isEmpty) return;
    final categories = context.read<CategoryListProvider>().categories;
    final picked = await showModalBottomSheet<(bool, int?)>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text('Set category'),
                  subtitle: Text('Apply to selected documents'),
                ),
                ListTile(
                  leading: const Icon(Icons.clear_rounded),
                  title: const Text('No category'),
                  onTap: () => Navigator.of(context).pop((true, null)),
                ),
                for (final c in categories)
                  ListTile(
                    leading: const Icon(Icons.label_outline_rounded),
                    title: Text(c.name),
                    onTap: () => Navigator.of(context).pop((true, c.id)),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || picked == null || picked.$1 != true) return;
    await context
        .read<DocumentListProvider>()
        .setCategoryForDocuments(selected, categoryId: picked.$2);
    if (!mounted) return;
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visibleDocs = provider.documents;
    _syncSelectionWithVisible(visibleDocs);
    final selectedVisibleDocs = _selectedVisibleDocuments(visibleDocs);
    final allVisibleSelected =
        visibleDocs.isNotEmpty && selectedVisibleDocs.length == visibleDocs.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: _selectionMode
                ? Text('${selectedVisibleDocs.length} selected')
                : const Text('Your vault'),
            actions: [
              if (_selectionMode) ...[
                IconButton(
                  tooltip: allVisibleSelected ? 'Clear selection' : 'Select all',
                  icon: Icon(
                    allVisibleSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                  onPressed: () {
                    if (allVisibleSelected) {
                      _clearSelection();
                    } else {
                      _selectAllVisible(visibleDocs);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Set category',
                  icon: const Icon(Icons.label_outline_rounded),
                  onPressed: selectedVisibleDocs.isEmpty
                      ? null
                      : () => _openBatchCategorySheet(selectedVisibleDocs),
                ),
                IconButton(
                  tooltip: _isExporting ? 'Exporting...' : 'Export selected',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: selectedVisibleDocs.isEmpty || _isExporting
                      ? null
                      : () => _exportDocuments(selectedVisibleDocs),
                ),
                IconButton(
                  tooltip: 'Delete selected',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error.withValues(alpha: 0.9),
                  ),
                  onPressed: selectedVisibleDocs.isEmpty
                      ? null
                      : () => _confirmBatchDelete(selectedVisibleDocs),
                ),
                IconButton(
                  tooltip: 'Close selection',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSelection,
                ),
              ] else ...[
                PopupMenuButton<VaultDocumentSort>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort_rounded),
                  initialValue: provider.sortMode,
                  onSelected: (VaultDocumentSort mode) {
                    context.read<DocumentListProvider>().setSortMode(mode);
                  },
                  itemBuilder: (context) => [
                    for (final s in VaultDocumentSort.values)
                      PopupMenuItem<VaultDocumentSort>(
                        value: s,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: s == provider.sortMode
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: scheme.primary,
                                    )
                                  : null,
                            ),
                            Text(s.menuLabel),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Filters',
                  onPressed: () => showDocumentFiltersSheet(context),
                  icon: Badge(
                    isLabelVisible: provider.hasStructuredFilters,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    backgroundColor: scheme.primary,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MultiProvider(
                          providers: [
                            Provider.value(
                              value: context.read<SecureStorageService>(),
                            ),
                            Provider.value(
                              value: context.read<ExpiryReminderService>(),
                            ),
                            ChangeNotifierProvider.value(
                              value: context.read<AuthStateProvider>(),
                            ),
                            ChangeNotifierProvider.value(
                              value: context.read<CategoryListProvider>(),
                            ),
                            ChangeNotifierProvider.value(
                              value: context.read<ThemeController>(),
                            ),
                          ],
                          child: const SettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.lock_person_outlined),
                  tooltip: 'Lock vault',
                  onPressed: () => context.read<AuthStateProvider>().lock(),
                ),
              ],
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    context.read<DocumentListProvider>().setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Search title or notes…',
                  prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                ),
              ),
            ),
          ),
          if (!_selectionMode && provider.hasActiveListFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (provider.searchQuery.isNotEmpty)
                      _FilterSummaryChip(
                        label: '“${provider.searchQuery.length > 28 ? '${provider.searchQuery.substring(0, 28)}…' : provider.searchQuery}”',
                        onDelete: () {
                          _searchController.clear();
                          context
                              .read<DocumentListProvider>()
                              .setSearchQuery('');
                        },
                      ),
                    if (provider.hasStructuredFilters)
                      ActionChip(
                        avatar: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        label: const Text('Edit filters'),
                        onPressed: () => showDocumentFiltersSheet(context),
                      ),
                    TextButton(
                      onPressed: _clearAllListFilters,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
            ),
          if (provider.isLoading && provider.documents.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.documents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.hasActiveListFilters
                            ? Icons.search_off_rounded
                            : Icons.folder_special_outlined,
                        size: 72,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        provider.hasActiveListFilters
                            ? 'No matching documents'
                            : 'No documents yet',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        provider.hasActiveListFilters
                            ? 'Try different search words or filters.'
                            : 'Add images, scans, or PDFs. Everything stays encrypted on this device.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (provider.hasActiveListFilters) ...[
                        const SizedBox(height: 20),
                        FilledButton.tonalIcon(
                          onPressed: _clearAllListFilters,
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Clear all'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: visibleDocs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = visibleDocs[index];
                  final isSelected = _selectedIds.contains(doc.id);
                  return VaultDocumentListCard(
                    document: doc,
                    onOpen: () {
                      if (_selectionMode) {
                        _toggleSelection(doc.id);
                        return;
                      }
                      _openViewer(doc);
                    },
                    onEdit: () {
                      if (_selectionMode) {
                        _toggleSelection(doc.id);
                        return;
                      }
                      _pushEditScreen(context, doc);
                    },
                    onDelete: () {
                      if (_selectionMode) {
                        _toggleSelection(doc.id);
                        return;
                      }
                      provider.deleteDocument(doc);
                    },
                    onDetails: _selectionMode ? null : () => _openDetailsSheet(doc),
                    selectionMode: _selectionMode,
                    selected: isSelected,
                    onToggleSelected: () => _toggleSelection(doc.id),
                    onLongPress: () {
                      if (!_selectionMode) {
                        _toggleSelection(doc.id);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    value: context.read<DocumentListProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<CategoryListProvider>(),
                  ),
                ],
                child: const EditDocumentScreen(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add document'),
      ),
    );
  }
}

class _FilterSummaryChip extends StatelessWidget {
  const _FilterSummaryChip({
    required this.label,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      onDeleted: onDelete,
    );
  }
}
