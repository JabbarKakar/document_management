import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';

enum ScanOutputFormat { pdf, image }

enum ScanEnhancementPreset {
  original('Original'),
  document('Document B/W'),
  highContrast('High contrast');

  const ScanEnhancementPreset(this.label);
  final String label;
}

/// Module 29 (MVP): multi-page camera scan flow with basic enhancements.
class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final _picker = ImagePicker();
  final List<Uint8List> _rawPages = [];
  bool _isCapturing = false;
  bool _isBuilding = false;
  ScanOutputFormat _output = ScanOutputFormat.pdf;
  ScanEnhancementPreset _preset = ScanEnhancementPreset.document;

  Future<void> _capturePage() async {
    if (_isCapturing || _isBuilding) return;
    setState(() => _isCapturing = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() => _rawPages.add(bytes));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Uint8List _applyPreset(Uint8List bytes, ScanEnhancementPreset preset) {
    if (preset == ScanEnhancementPreset.original) return bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    if (preset == ScanEnhancementPreset.document) {
      final g = img.grayscale(decoded);
      final c = img.contrast(g, contrast: 35);
      return Uint8List.fromList(img.encodeJpg(c, quality: 92));
    }

    final c1 = img.contrast(decoded, contrast: 55);
    final c2 = img.adjustColor(c1, saturation: 0.15, gamma: 1.05);
    return Uint8List.fromList(img.encodeJpg(c2, quality: 92));
  }

  Future<void> _finish() async {
    if (_rawPages.isEmpty || _isBuilding) return;
    setState(() => _isBuilding = true);
    try {
      final processed = _rawPages.map((b) => _applyPreset(b, _preset)).toList();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      late final PickedDocumentFile out;

      if (_output == ScanOutputFormat.pdf || processed.length > 1) {
        final pdf = pw.Document();
        for (final bytes in processed) {
          final mem = pw.MemoryImage(bytes);
          pdf.addPage(
            pw.Page(
              build: (_) => pw.Center(
                child: pw.Image(mem, fit: pw.BoxFit.contain),
              ),
            ),
          );
        }
        out = PickedDocumentFile(
          bytes: Uint8List.fromList(await pdf.save()),
          fileName: 'scan_$stamp.pdf',
          fileType: VaultDocumentFileType.pdf,
        );
      } else {
        out = PickedDocumentFile(
          bytes: processed.first,
          fileName: 'scan_$stamp.jpg',
          fileType: VaultDocumentFileType.image,
        );
      }
      if (mounted) Navigator.of(context).pop(out);
    } finally {
      if (mounted) setState(() => _isBuilding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan document'),
        actions: [
          TextButton(
            onPressed: _rawPages.isEmpty || _isBuilding ? null : _finish,
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                SegmentedButton<ScanEnhancementPreset>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in ScanEnhancementPreset.values)
                      ButtonSegment<ScanEnhancementPreset>(
                        value: p,
                        label: Text(p.label),
                      ),
                  ],
                  selected: {_preset},
                  onSelectionChanged: (s) => setState(() => _preset = s.first),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ScanOutputFormat>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<ScanOutputFormat>(
                      value: ScanOutputFormat.pdf,
                      label: Text('PDF'),
                    ),
                    ButtonSegment<ScanOutputFormat>(
                      value: ScanOutputFormat.image,
                      label: Text('Image'),
                    ),
                  ],
                  selected: {_output},
                  onSelectionChanged: (s) => setState(() => _output = s.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: _rawPages.isEmpty
                ? Center(
                    child: Text(
                      'Capture pages to build a scan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rawPages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final pageNo = index + 1;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _rawPages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Chip(label: Text('Page $pageNo')),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IconButton.filledTonal(
                              tooltip: 'Remove page',
                              onPressed: _isBuilding
                                  ? null
                                  : () => setState(() => _rawPages.removeAt(index)),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCapturing || _isBuilding ? null : _capturePage,
                  icon: _isCapturing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capture page'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _rawPages.isEmpty || _isBuilding ? null : _finish,
                  icon: _isBuilding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Use scan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

