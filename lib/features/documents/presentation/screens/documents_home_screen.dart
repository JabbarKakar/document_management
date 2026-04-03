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
import '../providers/document_list_provider.dart';
import 'document_viewer_screen.dart';
import 'edit_document_screen.dart';
import 'vault_document_list_card.dart';

class DocumentsHomeScreen extends StatelessWidget {
  const DocumentsHomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final categories = context.watch<CategoryListProvider>().categories;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Your vault'),
            actions: [
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: (v) => context.read<DocumentListProvider>().setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Search title or notes…',
                  prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: provider.categoryFilter == null,
                        showCheckmark: false,
                        onSelected: (_) =>
                            context.read<DocumentListProvider>().setCategoryFilter(null),
                      ),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.name),
                          selected: provider.categoryFilter == c.id,
                          showCheckmark: false,
                          onSelected: (_) => context
                              .read<DocumentListProvider>()
                              .setCategoryFilter(c.id),
                        ),
                      ),
                  ],
                ),
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
                        Icons.folder_special_outlined,
                        size: 72,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No documents yet',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add images, scans, or PDFs. Everything stays encrypted on this device.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
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
