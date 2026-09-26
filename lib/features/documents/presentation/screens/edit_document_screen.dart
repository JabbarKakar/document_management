import '../../../../core/widgets/vault_identity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/document_list_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/domain/entities/vault_category.dart';
import 'camera_scanner_screen.dart';

class EditDocumentScreen extends StatefulWidget {
  const EditDocumentScreen({super.key, this.existing});

  /// Existing documents retain their file unless a replacement is chosen.
  final VaultDocument? existing;

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;
  PickedDocumentFile? _pickedFile;
  bool _isSaving = false;
  VaultCategory? _selectedCategory;
  bool _categoryResolved = false;

  final _picker = DocumentFilePicker();

  bool get _isEditing => widget.existing != null;

  Future<void> _pickFile(Future<PickedDocumentFile?> Function() pick) async {
    try {
      final result = await pick();
      if (mounted && result != null) setState(() => _pickedFile = result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not open this file. Check access and try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _notesController.text = e.notes ?? '';
      _expiryDate = e.expiryDate;
    }
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _tryResolveCategoryFromExisting() {
    if (_categoryResolved) return;
    final e = widget.existing;
    if (e == null) {
      _categoryResolved = true;
      return;
    }
    if (e.categoryId == null) {
      _categoryResolved = true;
      return;
    }
    final cats = context.read<CategoryListProvider>().categories;
    VaultCategory? match;
    for (final c in cats) {
      if (c.id == e.categoryId) {
        match = c;
        break;
      }
    }
    if (match != null) {
      _categoryResolved = true;
      if (_selectedCategory?.id != match.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCategory = match);
        });
      }
      return;
    }
    if (cats.isEmpty) return;
    _categoryResolved = true;
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 120);
    final picked = await showDatePicker(
      useRootNavigator: false,
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final existing = widget.existing;
    if (existing != null) {
      setState(() => _isSaving = true);
      try {
        await context.read<DocumentListProvider>().saveExistingDocumentChanges(
          existing: existing,
          title: title,
          expiryDate: _expiryDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          categoryId: _selectedCategory?.id,
          replacementFile: _pickedFile,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error is FormatException
                    ? error.message
                    : 'Could not save changes. Unlock the vault and try again.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    if (_pickedFile == null) return;
    setState(() => _isSaving = true);
    try {
      final picked = _pickedFile!;
      await context.read<DocumentListProvider>().addDocumentFromPicker(
        title: title,
        pickedFile: picked,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        categoryId: _selectedCategory?.id,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not save the document. Your details have been kept.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _scanDocument() async {
    final result = await Navigator.of(context).push<PickedDocumentFile>(
      MaterialPageRoute<PickedDocumentFile>(
        builder: (_) => const CameraScannerScreen(),
      ),
    );
    if (result != null && mounted) setState(() => _pickedFile = result);
  }

  Widget _fileChoices(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEditing) ...[
              Text(
                'Choose a replacement only if you want to update the file.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.tonalIcon(
              onPressed: _scanDocument,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(_isEditing ? 'Scan a replacement' : 'Scan document'),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final single = MediaQuery.textScalerOf(context).scale(16) > 24;
                final width = single
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFile(_picker.pickFromGallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFile(_picker.captureFromCamera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickFile(_picker.pickPdf),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Choose PDF'),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedFile!.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove selected file',
                      onPressed: () => setState(() => _pickedFile = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categories = context.watch<CategoryListProvider>().categories;
    _tryResolveCategoryFromExisting();

    final canSave =
        _titleController.text.trim().isNotEmpty &&
        (_isEditing || _pickedFile != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit document' : 'Add document'),
      ),
      body: VaultAtmosphere(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VaultEyebrow('Keep what matters'),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing
                        ? 'Fine-tune the details.'
                        : 'A little more organized.',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Text('Details', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                            ),
                          ),
                          if (categories.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<VaultCategory?>(
                              key: ValueKey(_selectedCategory?.id),
                              initialValue: _selectedCategory,
                              items: [
                                const DropdownMenuItem<VaultCategory?>(
                                  value: null,
                                  child: Text('No category'),
                                ),
                                ...categories.map(
                                  (c) => DropdownMenuItem<VaultCategory?>(
                                    value: c,
                                    child: Text(c.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('File', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _fileChoices(context),
                  const SizedBox(height: 24),
                  Text('Expiry & notes', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickExpiryDate,
                            icon: const Icon(Icons.event_rounded),
                            label: Text(
                              _expiryDate == null
                                  ? 'Expiry date (optional)'
                                  : 'Expires ${_expiryDate!.toLocal().toString().split(' ').first}',
                            ),
                          ),
                          if (_expiryDate != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _expiryDate = null),
                                child: const Text('Clear expiry date'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _isSaving || !canSave ? null : _save,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _isSaving
                  ? 'Saving…'
                  : _isEditing
                  ? 'Save changes'
                  : 'Save to vault',
            ),
          ),
        ),
      ),
    );
  }
}
