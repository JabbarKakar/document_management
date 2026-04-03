import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_controller.dart';
import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/vault_document_sort.dart';
import '../providers/document_list_provider.dart';
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

  Future<void> _clearAllListFilters() async {
    _searchController.clear();
    await context.read<DocumentListProvider>().clearAllListFilters();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Your vault'),
            actions: [
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
          if (provider.hasActiveListFilters)
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
                itemCount: provider.documents.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = provider.documents[index];
                  return VaultDocumentListCard(
                    document: doc,
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              Provider<EncryptedFileStorageService>.value(
                                value: context
                                    .read<EncryptedFileStorageService>(),
                                child: DocumentViewerScreen(document: doc),
                              ),
                        ),
                      );
                    },
                    onEdit: () => _pushEditScreen(context, doc),
                    onDelete: () => provider.deleteDocument(doc),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (routeContext) => MultiProvider(
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
