import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/services/document_export_service.dart';
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
  bool _sharing = false;
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
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
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
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    final storage = context.read<EncryptedFileStorageService>();
    final exporter = context.read<DocumentExportService>();
    final confirmed = await showDialog<bool>(
      context: context, useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: const Text('Export document?'),
        content: const Text('This shares a decrypted copy outside your vault. The receiving app can keep its own copy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Export')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sharing = true);
    try {
      await exporter.exportDocumentsViaShare(
        documents: [widget.document], storage: storage,
        message: widget.document.title,
        sharePositionOrigin: Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 1),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not export. Unlock the vault and try again.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
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
            onPressed: _loading || _sharing || _error != null ? null : () => _share(),
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
      backgroundDecoration: const BoxDecoration(color: Colors.black),
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

