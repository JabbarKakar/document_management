import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/document_list_provider.dart';
import '../../../categories/presentation/providers/category_list_provider.dart';
import '../../../categories/domain/entities/vault_category.dart';

class EditDocumentScreen extends StatefulWidget {
  const EditDocumentScreen({super.key});

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

  final _picker = DocumentFilePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_pickedFile == null || _titleController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final picked = _pickedFile!;
    await context.read<DocumentListProvider>().addDocumentFromPicker(
          title: _titleController.text.trim(),
          pickedFile: picked,
          expiryDate: _expiryDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          categoryId: _selectedCategory?.id,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categories = context.watch<CategoryListProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add document'),
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
                              final result = await _picker.captureFromCamera();
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
                                _pickedFile!.fileType == VaultDocumentFileType.pdf
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
            onPressed:
                _isSaving || _pickedFile == null ? null : () => _save(),
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
            label: Text(_isSaving ? 'Saving…' : 'Save to vault'),
          ),
        ),
      ),
    );
  }
}
