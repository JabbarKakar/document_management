import '../../../../core/widgets/vault_identity.dart';
import '../widgets/vault_overview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/theme_controller.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../categories/domain/entities/vault_category.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../settings/presentation/screens/recovery_backup_screen.dart';
import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/expiry_calendar.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_details_sheet.dart';
import '../widgets/document_filters_sheet.dart';
import '../widgets/vault_home_widgets.dart';
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
  bool _isImporting = false;
  bool _gridView = false;
  bool _railExtended = true;
  final _picker = DocumentFilePicker();

  static const int _expiringWindowDays = 30;

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

  Future<bool> _ensureUnlocked({String? reason}) async {
    final auth = context.read<AuthStateProvider>();
    await auth.enforceAutoLockIfNeeded();
    if (!mounted) return false;
    if (auth.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason == null
                ? 'Vault locked. Enter your PIN to continue.'
                : 'Vault locked. Enter your PIN to $reason.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pushEditScreen(VaultDocument doc) async {
    if (!await _ensureUnlocked(reason: 'edit')) return;
    if (!mounted) return;
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

  Future<void> _openViewer(VaultDocument doc) async {
    if (!await _ensureUnlocked(reason: 'open')) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Provider<EncryptedFileStorageService>.value(
          value: context.read<EncryptedFileStorageService>(),
          child: DocumentViewerScreen(document: doc),
        ),
      ),
    );
  }

  Future<String?> _confirmExportCount(int count) async {
    final ok = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          count == 1 ? 'Export document?' : 'Export $count documents?',
        ),
        content: const Text(
          'Choose a password-protected package, or share decrypted copies. Shared copies are unencrypted outside the vault.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('plain'),
            child: const Text('Share copies'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('encrypted'),
            child: const Text('Encrypted package'),
          ),
        ],
      ),
    );
    return ok;
  }

  Future<void> _exportDocuments(List<VaultDocument> docs) async {
    if (docs.isEmpty || _isExporting) return;
    if (!await _ensureUnlocked(reason: 'export')) return;
    final format = await _confirmExportCount(docs.length);
    if (format == null) return;
    if (!mounted) return;
    if (format == 'encrypted') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              RecoveryBackupScreen(documentIds: docs.map((d) => d.id).toSet()),
        ),
      );
      return;
    }

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
      final result = await exportService.exportDocumentsViaShare(
        documents: docs,
        storage: storage,
        message: docs.length == 1 ? docs.first.title.trim() : null,
        sharePositionOrigin: Rect.fromLTWH(
          0,
          0,
          MediaQuery.sizeOf(context).width,
          1,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.status == ShareResultStatus.dismissed
                ? 'Export cancelled.'
                : 'Prepared ${docs.length} document(s) for sharing.',
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

  Future<int?> _pickImportCategory(List<VaultCategory> categories) async {
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
                  title: Text('Import category'),
                  subtitle: Text('Optional category for all imported files'),
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
    if (picked == null || picked.$1 != true) return null;
    return picked.$2;
  }

  Future<void> _startBulkImport({List<PickedDocumentFile>? retryFiles}) async {
    if (_isImporting) return;
    if (!await _ensureUnlocked(reason: 'import')) return;
    final List<PickedDocumentFile> files;
    try {
      files = retryFiles ?? await _picker.pickMultipleForImport();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not read these files. Please retry.',
            ),
          ),
        );
      }
      return;
    }
    if (files.isEmpty || !mounted) return;

    final categoryId = await _pickImportCategory(
      context.read<CategoryListProvider>().categories,
    );
    if (!mounted) return;

    final ok = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import ${files.length} files?'),
        content: Text(
          categoryId == null
              ? 'Files will be encrypted and added with no category.'
              : 'Files will be encrypted and added to the chosen category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final progress = ValueNotifier<(int, int, String)>((
      0,
      files.length,
      'Starting...',
    ));
    setState(() => _isImporting = true);
    var cancelled = false;
    showDialog<void>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Importing files'),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
              },
              child: const Text('Stop after current file'),
            ),
          ],
          content: ValueListenableBuilder<(int, int, String)>(
            valueListenable: progress,
            builder: (_, p, child) {
              final done = p.$1;
              final total = p.$2;
              final current = p.$3;
              final v = total == 0 ? 0.0 : done / total;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$done of $total'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: v),
                  const SizedBox(height: 12),
                  Text(current, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              );
            },
          ),
        ),
      ),
    );

    BulkImportReport? report;
    Object? importError;
    try {
      report = await context
          .read<DocumentListProvider>()
          .importDocumentsFromPickerFiles(
            files: files,
            categoryId: categoryId,
            isCancelled: () => cancelled,
            onProgress:
                ({
                  required int completed,
                  required int total,
                  required String fileName,
                }) {
                  progress.value = (completed, total, fileName);
                },
          );
    } catch (e) {
      importError = e;
    } finally {
      progress.dispose();
      if (mounted) {
        Navigator.of(context).pop(); // progress dialog
        setState(() => _isImporting = false);
      }
    }

    if (!mounted) return;
    if (importError != null || report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed. Please try again.')),
      );
      return;
    }
    final r = report;

    final retry = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cancelled ? 'Import stopped' : 'Import finished'),
        content: Text(
          r.retryFiles.isEmpty
              ? 'Imported ${r.succeeded} of ${r.total} files successfully.'
              : 'Imported ${r.succeeded} of ${r.total} files.\n'
                    '${r.failedNames.length} failed, ${r.total - r.succeeded - r.failedNames.length} not processed.\n${r.failedNames.take(5).join('\n')}',
        ),
        actions: [
          if (r.retryFiles.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retry remaining'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) {
      await _startBulkImport(retryFiles: r.retryFiles);
    }
  }

  Future<void> _openDetailsSheet(VaultDocument doc) async {
    if (!await _ensureUnlocked(reason: 'view details')) return;
    if (!mounted) return;
    showDocumentDetailsSheet(
      context,
      document: doc,
      onOpen: () => _openViewer(doc),
      onEdit: () => _pushEditScreen(doc),
      onDelete: () => _confirmBatchDelete([doc]),
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
        setState(
          () => _selectedIds.removeWhere((id) => !visibleIds.contains(id)),
        );
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
    if (!await _ensureUnlocked(reason: 'delete')) return;
    if (!mounted) return;
    final count = selected.length;
    final ok = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move $count document(s) to Trash?'),
        content: const Text(
          'Restore them from Settings → Trash for 30 days. Previous versions stay with each document until permanent deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (!await _ensureUnlocked(reason: 'delete')) return;
    if (!mounted) return;
    try {
      await context.read<DocumentListProvider>().deleteDocuments(selected);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some documents could not be deleted. Please retry.'),
          ),
        );
      }
      return;
    }
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
    await context.read<DocumentListProvider>().setCategoryForDocuments(
      selected,
      categoryId: picked.$2,
    );
    if (!mounted) return;
    _clearSelection();
  }

  void _openAddDocument() {
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
  }

  void _openCategories() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<CategoryListProvider>(),
          child: const CategoryManagementScreen(),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            Provider.value(value: context.read<SecureStorageService>()),
            Provider.value(value: context.read<ExpiryReminderService>()),
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
  }

  String? _categoryName(int? id, List<VaultCategory> categories) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }

  int _expiringCount(List<VaultDocument> documents) {
    var count = 0;
    for (final document in documents) {
      final expiry = document.expiryDate;
      if (expiry == null) continue;
      if (calendarDaysUntilExpiry(expiry) <= _expiringWindowDays) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final categories = context.watch<CategoryListProvider>().categories;
    final scheme = Theme.of(context).colorScheme;
    final visibleDocs = provider.documents;
    _syncSelectionWithVisible(visibleDocs);
    final selectedVisibleDocs = _selectedVisibleDocuments(visibleDocs);
    final allVisibleSelected =
        visibleDocs.isNotEmpty &&
        selectedVisibleDocs.length == visibleDocs.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.rail;
        final railWidth = _railExtended ? 208.0 : 80.0;
        final contentWidth = wide
            ? constraints.maxWidth - railWidth
            : constraints.maxWidth;
        final columns =
            MediaQuery.textScalerOf(context).scale(16) > 24 ||
                contentWidth < 360
            ? 1
            : contentWidth >= AppBreakpoints.gridThree
            ? 3
            : 2;
        final textScaler = MediaQuery.textScalerOf(context);
        final gridExtent = textScaler.scale(312);

        return Scaffold(
          extendBody: _selectionMode,
          floatingActionButton: _selectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openAddDocument,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add document'),
                ),
          bottomNavigationBar: _selectionMode
              ? VaultSelectionBar(
                  count: selectedVisibleDocs.length,
                  allSelected: allVisibleSelected,
                  actionsEnabled: selectedVisibleDocs.isNotEmpty,
                  exporting: _isExporting,
                  onToggleSelectAll: () {
                    if (allVisibleSelected) {
                      _clearSelection();
                    } else {
                      _selectAllVisible(visibleDocs);
                    }
                  },
                  onCategory: () =>
                      _openBatchCategorySheet(selectedVisibleDocs),
                  onExport: () => _exportDocuments(selectedVisibleDocs),
                  onDelete: () => _confirmBatchDelete(selectedVisibleDocs),
                  onClose: _clearSelection,
                )
              : wide
              ? null
              : NavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (index) {
                    if (index == 1) _openCategories();
                    if (index == 2) _openSettings();
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Library',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.folder_outlined),
                      label: 'Categories',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.tune_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
          body: SafeArea(
            bottom: !_selectionMode,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  VaultHomeRail(
                    extended: _railExtended,
                    onToggleExtended: () =>
                        setState(() => _railExtended = !_railExtended),
                    onCategories: _openCategories,
                    onSettings: _openSettings,
                  ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const VaultMark(size: 40),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Vault',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Lock vault',
                                    onPressed: () => context
                                        .read<AuthStateProvider>()
                                        .lock(),
                                    icon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              VaultSearchField(
                                controller: _searchController,
                                onChanged: (value) => context
                                    .read<DocumentListProvider>()
                                    .setSearchQuery(value),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              VaultOverview(
                                documents: provider.allDocuments.length,
                                attention: _expiringCount(
                                  provider.allDocuments,
                                ),
                                onAttention: () =>
                                    provider.setSmartView('expiring'),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Your library',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              VaultBrowserToolbar(
                                grid: _gridView,
                                onViewMode: (grid) =>
                                    setState(() => _gridView = grid),
                                sortMode: provider.sortMode,
                                onSort: (mode) => context
                                    .read<DocumentListProvider>()
                                    .setSortMode(mode),
                                filtersActive: provider.hasStructuredFilters,
                                onFilters: () =>
                                    showDocumentFiltersSheet(context),
                                importing: _isImporting,
                                onImport: _isImporting
                                    ? null
                                    : _startBulkImport,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final entry in const {
                                  'all': 'All',
                                  'favorites': 'Favorites',
                                  'uncategorized': 'Uncategorized',
                                  'expiring': 'Expiry attention',
                                  'recent': 'Recent',
                                }.entries)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(entry.value),
                                      selected: provider.smartView == entry.key,
                                      onSelected: (_) =>
                                          provider.setSmartView(entry.key),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (provider.errorMessage != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              0,
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: AppRadius.cardBorder,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Text(
                                    provider.errorMessage!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onErrorContainer,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!_selectionMode && provider.hasActiveListFilters)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              0,
                            ),
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (provider.searchQuery.isNotEmpty)
                                  _FilterSummaryChip(
                                    label:
                                        '“${provider.searchQuery.length > 28 ? '${provider.searchQuery.substring(0, 28)}…' : provider.searchQuery}”',
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
                                    onPressed: () =>
                                        showDocumentFiltersSheet(context),
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
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: VaultListSkeleton(
                              grid: _gridView,
                              columns: columns,
                            ),
                          ),
                        )
                      else if (provider.documents.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: VaultEmptyState(
                            filtered: provider.hasActiveListFilters,
                            onClear: _clearAllListFilters,
                            onAdd: _openAddDocument,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            _selectionMode ? 112 : 120,
                          ),
                          sliver: _gridView
                              ? SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisSpacing: AppSpacing.sm,
                                        crossAxisSpacing: AppSpacing.sm,
                                        mainAxisExtent: gridExtent,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return _documentCard(
                                      visibleDocs[index],
                                      categories,
                                      layout: VaultDocumentCardLayout.grid,
                                    );
                                  }, childCount: visibleDocs.length),
                                )
                              : SliverList.separated(
                                  itemCount: visibleDocs.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    return _documentCard(
                                      visibleDocs[index],
                                      categories,
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _documentCard(
    VaultDocument doc,
    List<VaultCategory> categories, {
    VaultDocumentCardLayout layout = VaultDocumentCardLayout.list,
  }) {
    final isSelected = _selectedIds.contains(doc.id);
    return VaultDocumentListCard(
      document: doc,
      categoryName: _categoryName(doc.categoryId, categories),
      layout: layout,
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
        _pushEditScreen(doc);
      },
      onDelete: () {
        if (_selectionMode) {
          _toggleSelection(doc.id);
          return;
        }
        _confirmBatchDelete([doc]);
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
  }
}

class _FilterSummaryChip extends StatelessWidget {
  const _FilterSummaryChip({required this.label, required this.onDelete});

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
