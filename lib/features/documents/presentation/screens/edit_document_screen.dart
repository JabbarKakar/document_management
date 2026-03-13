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
    final theme = Theme.of(context);
    final categories = context.watch<CategoryListProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (categories.isNotEmpty)
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
                  border: OutlineInputBorder(),
                ),
              ),
            if (categories.isNotEmpty) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await _picker.pickFromGallery();
                      if (result != null) {
                        setState(() {
                          _pickedFile = result;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await _picker.captureFromCamera();
                      if (result != null) {
                        setState(() {
                          _pickedFile = result;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await _picker.pickPdf();
                if (result != null) {
                  setState(() {
                    _pickedFile = result;
                  });
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Import PDF'),
            ),
            const SizedBox(height: 8),
            if (_pickedFile != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _pickedFile!.fileType == VaultDocumentFileType.pdf
                          ? Icons.picture_as_pdf
                          : Icons.image_outlined,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFile!.fileName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickExpiryDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _expiryDate == null
                          ? 'Set expiry (optional)'
                          : 'Expires: ${_expiryDate!.toLocal().toString().split(' ').first}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving || _pickedFile == null ? null : () => _save(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save document'),
            ),
          ),
        ),
      ),
    );
  }
}

