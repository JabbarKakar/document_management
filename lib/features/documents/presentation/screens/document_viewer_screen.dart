import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../domain/entities/vault_document.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final VaultDocument document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PdfControllerPinch? _pdfController;
  Uint8List? _imageBytes;
  File? _tempPdfFile;
  bool _loading = true;
  String? _error;
  bool _loadStarted = false;

  bool get _isPdf =>
      widget.document.fileType == VaultDocumentFileType.pdf ||
      widget.document.filePath.toLowerCase().endsWith('.pdf');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _decryptAndPrepare();
  }

  Future<void> _decryptAndPrepare() async {
    final storage = context.read<EncryptedFileStorageService>();
    try {
      final bytes = await storage.readDecryptedBytes(widget.document.filePath);
      if (!mounted) return;
      if (_isPdf) {
        final tempDir = await getTemporaryDirectory();
        _tempPdfFile = File(
          p.join(
            tempDir.path,
            'vault_view_${widget.document.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          ),
        );
        await _tempPdfFile!.writeAsBytes(bytes, flush: true);
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(_tempPdfFile!.path),
        );
      } else {
        _imageBytes = bytes;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    try {
      _tempPdfFile?.deleteSync();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _share() async {
    final path = widget.document.filePath;
    if (path.isEmpty) return;
    if (!File(path).existsSync()) return;

    final storage = context.read<EncryptedFileStorageService>();
    final bytes = await storage.readDecryptedBytes(path);
    final docTitle = widget.document.title.trim();
    final ext = p.extension(path);
    final shareExt = ext.isNotEmpty ? ext : (_isPdf ? '.pdf' : '.bin');
    final tempDir = await getTemporaryDirectory();
    final safeTitle = docTitle.isEmpty
        ? 'document'
        : docTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final newPath = p.join(tempDir.path, '$safeTitle$shareExt');
    final outFile = File(newPath);
    await outFile.writeAsBytes(bytes, flush: true);

    if (!mounted) return;
    await Share.shareXFiles(
      [XFile(outFile.path)],
      text: docTitle.isEmpty ? null : docTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.document.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.isEmpty ? 'Document' : title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _loading || _error != null ? null : () => _share(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not open document.\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return _isPdf ? _buildPdfView() : _buildImageView();
  }

  Widget _buildPdfView() {
    final controller = _pdfController;
    if (controller == null) {
      return const Center(child: Text('Unable to open PDF.'));
    }

    return PdfViewPinch(
      controller: controller,
      backgroundDecoration: const BoxDecoration(
        color: Colors.black,
      ),
    );
  }

  Widget _buildImageView() {
    final bytes = _imageBytes;
    if (bytes == null || bytes.isEmpty) {
      return const Center(child: Text('File not found.'));
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: PhotoView(
          imageProvider: MemoryImage(bytes),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained * 0.9,
          maxScale: PhotoViewComputedScale.covered * 4.0,
        ),
      ),
    );
  }
}
