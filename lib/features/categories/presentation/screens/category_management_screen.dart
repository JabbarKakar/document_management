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
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
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
            'Are you sure you want to delete this category? '
            'You cannot delete categories that still contain documents.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final ok =
        await context.read<CategoryListProvider>().deleteCategory(category);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete category that has documents.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryListProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage categories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addCategory(context),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.builder(
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: category.isDefault
                      ? const Text(
                          'Default',
                          style: TextStyle(fontSize: 12),
                        )
                      : null,
                  onTap: () => _renameCategory(context, category),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteCategory(context, category),
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

