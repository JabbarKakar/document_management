import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/vault_document.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final VaultDocument document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PdfControllerPinch? _pdfController;

  bool get _isPdf =>
      widget.document.fileType == VaultDocumentFileType.pdf ||
      widget.document.filePath.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    if (_isPdf) {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.document.filePath),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final path = widget.document.filePath;
    if (path.isEmpty || !File(path).existsSync()) return;

    // Some apps (like WhatsApp) ignore caption text for PDFs.
    // To make the title visible, we include it in the shared filename.
    final docTitle = widget.document.title.trim();
    final original = File(path);
    final ext = p.extension(path);

    final tempDir = await getTemporaryDirectory();
    final safeTitle = docTitle.isEmpty
        ? 'document'
        : docTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final newPath = p.join(tempDir.path, '$safeTitle$ext');

    // Copy to temp with a user-friendly name.
    final sharedFile = await original.copy(newPath);

    await Share.shareXFiles(
      [XFile(sharedFile.path)],
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
            icon: const Icon(Icons.ios_share),
            onPressed: _share,
          ),
        ],
      ),
      body: _isPdf ? _buildPdfView() : _buildImageView(),
    );
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
    final path = widget.document.filePath;
    if (path.isEmpty || !File(path).existsSync()) {
      return const Center(child: Text('File not found.'));
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: PhotoView(
          imageProvider: FileImage(File(path)),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained * 0.9,
          maxScale: PhotoViewComputedScale.covered * 4.0,
        ),
      ),
    );
  }
}

