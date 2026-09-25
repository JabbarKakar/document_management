import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/document_list_provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});
  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  Future<List<VaultDocument>>? _items;
  final _selected = <int>{};
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= _load();
  }

  Future<List<VaultDocument>> _load() async {
    final provider = context.read<DocumentListProvider>();
    await provider.purgeExpiredTrash();
    return provider.getTrash();
  }

  Future<void> _act(bool purge) async {
    if (_busy || _selected.isEmpty) return;
    if (purge) {
      final ok = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (context) => AlertDialog(
          title: Text('Permanently delete ${_selected.length} documents?'),
          content: const Text(
            'This removes the selected files and all their previous versions. You can only recover them from a separate backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final provider = context.read<DocumentListProvider>();
    setState(() => _busy = true);
    try {
      for (final id in _selected.toList()) {
        if (purge) {
          await provider.purgeDocument(id);
        } else {
          await provider.restoreDocument(id);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Some items could not be processed. Unlock and retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _selected.clear();
          _items = provider.getTrash();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trash')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Documents stay recoverable for 30 days. Expired Trash is permanently cleared when you next open the vault. Previous versions are kept with each trashed document.',
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: FutureBuilder<List<VaultDocument>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() => _items = _load()),
                    child: const Text('Could not load Trash. Retry'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final documents = snapshot.data!;
              if (documents.isEmpty) {
                return const Center(child: Text('Trash is empty'));
              }
              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final remaining =
                      (30 - DateTime.now().difference(doc.deletedAt!).inDays)
                          .clamp(0, 30);
                  return CheckboxListTile(
                    title: Text(doc.title),
                    subtitle: Text(
                      '$remaining days remaining · ${doc.versions.length} previous versions',
                    ),
                    value: _selected.contains(doc.id),
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            if (value == true) {
                              _selected.add(doc.id);
                            } else {
                              _selected.remove(doc.id);
                            }
                          }),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy || _selected.isEmpty ? null : () => _act(false),
              icon: const Icon(Icons.restore),
              label: Text('Restore (${_selected.length})'),
            ),
            OutlinedButton(
              onPressed: _busy || _selected.isEmpty ? null : () => _act(true),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
      ),
    ),
  );
}
