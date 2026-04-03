import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_list_provider.dart';
import '../../domain/entities/vault_category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory(BuildContext context) async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    await context.read<CategoryListProvider>().createCategory(name);
    _newCategoryController.clear();
  }

  Future<void> _renameCategory(
    BuildContext context,
    VaultCategory category,
  ) async {
    final controller = TextEditingController(text: category.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty && context.mounted) {
      await context
          .read<CategoryListProvider>()
          .renameCategory(category, newName);
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    VaultCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: const Text(
            'You cannot delete a category that still contains documents.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final ok =
        await context.read<CategoryListProvider>().deleteCategory(category);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a category that has documents.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryListProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'New category name',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addCategory(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _addCategory(context),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (provider.isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              color: scheme.primary,
            ),
          Expanded(
            child: provider.categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No categories yet. Add one above.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: provider.categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                scheme.primaryContainer.withValues(alpha: 0.9),
                            foregroundColor: scheme.onPrimaryContainer,
                            child: const Icon(Icons.label_outline_rounded),
                          ),
                          title: Text(category.name),
                          subtitle: category.isDefault
                              ? Text(
                                  'Default',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.tertiary,
                                        letterSpacing: 0.06,
                                      ),
                                )
                              : null,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error.withValues(alpha: 0.85),
                            ),
                            onPressed: () => _deleteCategory(context, category),
                          ),
                          onTap: () => _renameCategory(context, category),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
