import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../categories/presentation/providers/category_list_provider.dart';
import '../providers/document_list_provider.dart';
import 'document_viewer_screen.dart';
import 'edit_document_screen.dart';

class DocumentsHomeScreen extends StatelessWidget {
  const DocumentsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final categories = context.watch<CategoryListProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Documents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    context
                        .read<DocumentListProvider>()
                        .applySearch(query: value);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by title or notes',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: false,
                        onSelected: (_) {
                          context
                              .read<DocumentListProvider>()
                              .applySearch(categoryId: null);
                        },
                      ),
                      const SizedBox(width: 8),
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: false,
                            onSelected: (_) {
                              context
                                  .read<DocumentListProvider>()
                                  .applySearch(categoryId: c.id);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: provider.isLoading && provider.documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.documents.isEmpty
              ? const Center(
                  child: Text('No documents yet.'),
                )
              : ListView.builder(
                  itemCount: provider.documents.length,
                  itemBuilder: (context, index) {
                    final doc = provider.documents[index];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentViewerScreen(
                              document: doc,
                            ),
                          ),
                        );
                      },
                      title: Text(doc.title),
                      subtitle: Text(
                        doc.fileType.name.toUpperCase(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            provider.deleteDocument(doc),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
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
        icon: const Icon(Icons.add),
        label: const Text('Add document'),
      ),
    );
  }
}

