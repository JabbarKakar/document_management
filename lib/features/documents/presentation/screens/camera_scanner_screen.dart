import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/scan_processing.dart';
import '../../data/services/document_import_validation.dart';

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
  final Map<Uint8List, Future<Uint8List>> _previews = {};
  bool _isCapturing = false;
  bool _isBuilding = false;
  ScanOutputFormat _output = ScanOutputFormat.pdf;
  ScanEnhancementPreset _preset = ScanEnhancementPreset.document;

  void _showError(Object error) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
      error is FormatException ? error.message : 'Could not process the scan. Your captured pages are still available.')));
  }

  Future<void> _editPage(int index, String action) async {
    if (_isBuilding || _isCapturing) return;
    if (action == 'earlier' || action == 'later') {
      setState(() { final page = _rawPages.removeAt(index); _rawPages.insert(index + (action == 'earlier' ? -1 : 1), page); });
      return;
    }
    final crop = <double>[0, 0, 0, 0];
    if (action == 'crop') {
      var preview = compute(processScanPage, (_rawPages[index], _preset.index, 0, List<double>.from(crop), 700));
      final ok = await showDialog<bool>(context: context, useRootNavigator: false,
        builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
          title: const Text('Crop page edges'),
          content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 150, child: FutureBuilder<Uint8List>(future: preview, builder: (context, snapshot) =>
              snapshot.connectionState == ConnectionState.done && snapshot.hasData ? Image.memory(snapshot.data!, fit: BoxFit.contain) : const Center(child: CircularProgressIndicator()))),
            for (var i = 0; i < 4; i++) Column(children: [
              Text('${['Left', 'Top', 'Right', 'Bottom'][i]}: ${(crop[i] * 100).round()}%'),
              Slider(value: crop[i], min: 0, max: 0.45, divisions: 45,
                semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
                onChanged: (v) => update(() => crop[i] = v),
                onChangeEnd: (_) => update(() => preview = compute(processScanPage,
                  (_rawPages[index], _preset.index, 0, List<double>.from(crop), 700)))),
            ]),
          ]))),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply'))],
        )));
      if (ok != true || !mounted) return;
    }
    setState(() => _isBuilding = true);
    try {
      final original = _rawPages[index];
      final edited = await compute(processScanPage, (original, 0, action == 'rotate' ? 1 : 0, crop, 3200));
      if (mounted) setState(() { _rawPages[index] = edited; _previews.remove(original); });
    } catch (error) { _showError(error); }
    finally { if (mounted) setState(() => _isBuilding = false); }
  }

  Future<void> _capturePage() async {
    if (_isCapturing || _isBuilding) return;
    setState(() => _isCapturing = true);
    try {
      if (_rawPages.length >= 20) throw const FormatException('Save this scan before capturing more than 20 pages.');
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 3200, maxHeight: 3200,
      );
      if (picked == null) return;
      final size = await picked.length();
      if (size > DocumentImportLimits.fileBytes || _rawPages.fold<int>(0, (sum, b) => sum + b.length) + size > DocumentImportLimits.batchBytes) {
        throw const FormatException('This scan is too large. Save it before adding more pages.');
      }
      final bytes = await picked.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      final preview = await compute(processScanPage, (bytes, _preset.index, 0, <double>[0,0,0,0], 700));
      if (!mounted) return;
      setState(() { _rawPages.add(bytes); _previews[bytes] = Future.value(preview); if (_rawPages.length > 1) _output = ScanOutputFormat.pdf; });
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _finish() async {
    if (_rawPages.isEmpty || _isBuilding) return;
    setState(() => _isBuilding = true);
    try {
      final processed = <Uint8List>[];
      for (final page in _rawPages) {
        processed.add(await compute(processScanPage, (page, _preset.index, 0, <double>[0,0,0,0], 2200)));
      }
      final stamp = DateTime.now().millisecondsSinceEpoch;
      late final PickedDocumentFile out;

      if (_output == ScanOutputFormat.pdf || processed.length > 1) {
        final pdfBytes = await compute(assembleScanPdf, processed);
        out = PickedDocumentFile(
          bytes: pdfBytes,
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
      await validateDocumentImport(out.bytes, out.fileName, out.fileType);
      if (mounted) Navigator.of(context).pop(out);
    } catch (error) {
      _showError(error);
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
                  onSelectionChanged: _isBuilding ? null : (s) => setState(() { _preset = s.first; _previews.clear(); }),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ScanOutputFormat>(
                  showSelectedIcon: false,
                  segments: [
                    const ButtonSegment<ScanOutputFormat>(
                      value: ScanOutputFormat.pdf,
                      label: Text('PDF'),
                    ),
                    ButtonSegment<ScanOutputFormat>(
                      value: ScanOutputFormat.image,
                      label: const Text('Image'),
                      enabled: _rawPages.length <= 1,
                    ),
                  ],
                  selected: {_output},
                  onSelectionChanged: _isBuilding ? null : (s) => setState(() => _output = s.first),
                ),
                if (_rawPages.length > 1) const Text('Multiple pages are saved together as a PDF.'),
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
                              child: FutureBuilder<Uint8List>(
                                future: _previews.putIfAbsent(_rawPages[index], () => compute(processScanPage,
                                  (_rawPages[index], _preset.index, 0, <double>[0,0,0,0], 700))),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) return const Center(child: Text('Preview unavailable'));
                                  if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  return Image.memory(snapshot.data!, fit: BoxFit.contain);
                                },
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
                          Positioned(right: 4, bottom: 4, child: PopupMenuButton<String>(
                            tooltip: 'Edit page $pageNo', enabled: !_isBuilding && !_isCapturing,
                            onSelected: (action) => _editPage(index, action),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'rotate', child: Text('Rotate clockwise')),
                              const PopupMenuItem(value: 'crop', child: Text('Crop edges')),
                              if (index > 0) const PopupMenuItem(value: 'earlier', child: Text('Move earlier')),
                              if (index < _rawPages.length - 1) const PopupMenuItem(value: 'later', child: Text('Move later')),
                            ],
                          )),
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


