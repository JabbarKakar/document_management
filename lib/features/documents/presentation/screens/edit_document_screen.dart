import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/document_list_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/domain/entities/vault_category.dart';

class EditDocumentScreen extends StatefulWidget {
  const EditDocumentScreen({super.key, this.existing});

  /// When set, screen edits metadata only (file stays the same).
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
    final firstDate = _isEditing ? DateTime(now.year - 120) : now;
    final picked = await showDatePicker(
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categories = context.watch<CategoryListProvider>().categories;
    _tryResolveCategoryFromExisting();

    final canSave = _titleController.text.trim().isNotEmpty &&
        (_isEditing || _pickedFile != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit document' : 'Add document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: textTheme.titleMedium,
            ),
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
                        value: _selectedCategory,
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
            Text(
              'File',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.existing!.fileType == VaultDocumentFileType.pdf
                                ? Icons.picture_as_pdf_rounded
                                : widget.existing!.fileType ==
                                        VaultDocumentFileType.image
                                    ? Icons.image_outlined
                                    : Icons.insert_drive_file_outlined,
                            color: scheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Current encrypted file stays unless you choose a replacement below.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await _picker.pickFromGallery();
                                if (result != null) {
                                  setState(() => _pickedFile = result);
                                }
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Replace from gallery'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result =
                                    await _picker.captureFromCamera();
                                if (result != null) {
                                  setState(() => _pickedFile = result);
                                }
                              },
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Replace by camera'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await _picker.pickPdf();
                          if (result != null) {
                            setState(() => _pickedFile = result);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Replace with PDF'),
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 14),
                        Material(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickedFile!.fileType ==
                                          VaultDocumentFileType.pdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_outlined,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedFile!.fileName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Cancel replacement',
                                  onPressed: () => setState(() => _pickedFile = null),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await _picker.pickFromGallery();
                                if (result != null) {
                                  setState(() => _pickedFile = result);
                                }
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result =
                                    await _picker.captureFromCamera();
                                if (result != null) {
                                  setState(() => _pickedFile = result);
                                }
                              },
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await _picker.pickPdf();
                          if (result != null) {
                            setState(() => _pickedFile = result);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Import PDF'),
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 14),
                        Material(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickedFile!.fileType ==
                                          VaultDocumentFileType.pdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_outlined,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedFile!.fileName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Expiry & notes',
              style: textTheme.titleMedium,
            ),
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
                          onPressed: () => setState(() => _expiryDate = null),
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
