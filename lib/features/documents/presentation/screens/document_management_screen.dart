import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/document_list_provider.dart';
import 'document_viewer_screen.dart';
import '../../../../core/services/document_ocr_service.dart';
import '../../../../core/services/encrypted_file_storage_service.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key, required this.document});
  final VaultDocument document;
  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  late final _tags = TextEditingController(
    text: widget.document.tags.join(', '),
  );
  late final _offsets = TextEditingController(
    text: widget.document.reminderOffsets.join(', '),
  );
  bool _busy = false;
  bool _cancelOcr = false;
  bool _extracting = false;
  String? _ocrStatus;

  Future<void> _extract(VaultDocument document) async {
    final storage = context.read<EncryptedFileStorageService>();
    final provider = context.read<DocumentListProvider>();
    _cancelOcr = false;
    setState(() {
      _extracting = true;
      _ocrStatus = 'Reading text on this device…';
    });
    await _run(() async {
      final text = await DocumentOcrService(storage).extract(
        document,
        isCancelled: () => _cancelOcr || !mounted,
        onProgress: (done, total) {
          if (mounted) {
            setState(() => _ocrStatus = 'Read $done of $total pages');
          }
        },
      );
      if (_cancelOcr || !mounted) return;
      await provider.updateOrganization(
        document.id,
        extractedText: text,
        expectedFilePath: document.filePath,
      );
      if (mounted) {
        setState(
          () => _ocrStatus = text.isEmpty
              ? 'No text found. Try a clearer scan.'
              : 'Text saved for search. Please check recognition accuracy.',
        );
      }
    });
    if (mounted) setState(() => _extracting = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DocumentListProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _tags.dispose();
    _offsets.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not update this document. Unlock and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentListProvider>();
    final doc = provider.documentById(widget.document.id) ?? widget.document;
    return Scaffold(
      appBar: AppBar(title: const Text('Document organization')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(doc.title, style: Theme.of(context).textTheme.headlineSmall),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Favorite'),
                subtitle: const Text('Show in the Favorites view'),
                value: doc.isFavorite,
                onChanged: _busy
                    ? null
                    : (value) => _run(
                        () => provider.updateOrganization(
                          doc.id,
                          favorite: value,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Separate tags with commas. Up to 20 tags.',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => provider.updateOrganization(
                          doc.id,
                          tags: _tags.text.split(','),
                        ),
                      ),
                child: const Text('Save tags'),
              ),
              const Divider(),
              Text(
                'Searchable text',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Extract English/Latin text on this device. Up to 20 MB and 20 PDF pages. Recognition may contain mistakes.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _extract(doc),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Extract text'),
                  ),
                  if (_extracting)
                    TextButton(
                      onPressed: () => setState(() {
                        _cancelOcr = true;
                        _ocrStatus = 'Stopping after the current page…';
                      }),
                      child: const Text('Cancel'),
                    ),
                  if (doc.extractedText?.isNotEmpty == true)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => provider.updateOrganization(
                                doc.id,
                                extractedText: '',
                              ),
                            ),
                      child: const Text('Clear search text'),
                    ),
                ],
              ),
              if (_ocrStatus != null) Text(_ocrStatus!),
              if (doc.extractedText?.isNotEmpty == true)
                ExpansionTile(
                  title: const Text('Review extracted text'),
                  children: [SelectableText(doc.extractedText!)],
                ),
              const Divider(),
              Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminders for this document'),
                value: !doc.remindersDisabled,
                onChanged: _busy
                    ? null
                    : (value) => _run(
                        () => provider.updateOrganization(
                          doc.id,
                          remindersDisabled: !value,
                        ),
                      ),
              ),
              TextField(
                controller: _offsets,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Days before expiry',
                  helperText:
                      'Up to 5 offsets, 0–365 days. Leave blank for 30, 15, 7.',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final values = _offsets.text.trim().isEmpty
                            ? <int>[]
                            : _offsets.text.split(',').map((v) {
                                final days = int.tryParse(v.trim());
                                if (days == null) {
                                  throw const FormatException(
                                    'Enter whole numbers separated by commas.',
                                  );
                                }
                                return days;
                              }).toList();
                        await provider.updateOrganization(
                          doc.id,
                          reminderOffsets: values,
                        );
                      }),
                child: const Text('Save reminder schedule'),
              ),
              const Divider(),
              Text(
                'Previous file versions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'The last 3 replaced files are retained. Restoring an older file keeps the current file as a previous version.',
              ),
              if (doc.versions.isEmpty)
                const ListTile(title: Text('No previous versions yet')),
              for (final version in doc.versions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    version.createdAt.toLocal().toString().split('.').first,
                  ),
                  subtitle: Text(
                    VaultDocumentFileType.values[version.typeIndex].name
                        .toUpperCase(),
                  ),
                  leading: IconButton(
                    tooltip: 'Preview previous version',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DocumentViewerScreen(
                          document: VaultDocument(
                            id: doc.id,
                            title: '${doc.title} — previous version',
                            filePath: version.path,
                            createdAt: version.createdAt,
                            fileType:
                                VaultDocumentFileType.values[version.typeIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              useRootNavigator: false,
                              builder: (context) => AlertDialog(
                                title: const Text('Restore this file version?'),
                                content: const Text(
                                  'Your title, tags, notes and expiry stay unchanged.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Restore'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await _run(
                                () => provider.restoreVersion(
                                  doc.id,
                                  version.path,
                                ),
                              );
                            }
                          },
                    child: const Text('Restore'),
                  ),
                ),
              const Divider(),
              Text('Activity', style: Theme.of(context).textTheme.titleLarge),
              const Text(
                'Private local history, up to 200 events. This is not a tamper-proof audit log.',
              ),
              for (final event in doc.activity)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.action),
                  subtitle: Text(
                    event.at.toLocal().toString().split('.').first,
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
