import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/vault_document.dart';
import 'document_import_validation.dart';

class PickedDocumentFile {
  PickedDocumentFile({
    required this.bytes,
    required this.fileName,
    required this.fileType,
  });

  final Uint8List bytes;
  final String fileName;
  final VaultDocumentFileType fileType;
}

class DocumentFilePicker {
  DocumentFilePicker({
    ImagePicker? imagePicker,
    FilePicker? filePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _filePicker = filePicker ?? FilePicker.platform;

  final ImagePicker _imagePicker;
  final FilePicker _filePicker;

  Future<PickedDocumentFile?> pickFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    _checkSize(await picked.length());
    final bytes = await picked.readAsBytes();
    return PickedDocumentFile(
      bytes: bytes,
      fileName: picked.name,
      fileType: VaultDocumentFileType.image,
    );
  }

  Future<PickedDocumentFile?> captureFromCamera() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;

    _checkSize(await picked.length());
    final bytes = await picked.readAsBytes();
    return PickedDocumentFile(
      bytes: bytes,
      fileName: picked.name,
      fileType: VaultDocumentFileType.image,
    );
  }

  Future<PickedDocumentFile?> pickPdf() async {
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    final file = result?.files.single;
    if (file == null) return null;

    return PickedDocumentFile(
      bytes: await _readBounded(file),
      fileName: file.name,
      fileType: VaultDocumentFileType.pdf,
    );
  }

  Future<List<PickedDocumentFile>> pickMultipleForImport() async {
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      withData: false,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'bmp',
        'gif',
        'heic',
      ],
    );

    final files = result?.files ?? const [];
    if (files.length > DocumentImportLimits.batchFiles ||
        files.fold<int>(0, (total, file) => total + file.size) > DocumentImportLimits.batchBytes) {
      throw const FormatException('Import up to 50 files and 64 MB per batch.');
    }
    final out = <PickedDocumentFile>[];
    var totalBytes = 0;
    for (final f in files) {
      final bytes = await _readBounded(f);
      totalBytes += bytes.length;
      if (totalBytes > DocumentImportLimits.batchBytes) throw const FormatException('Import up to 64 MB per batch.');
      final type = _detectTypeFromName(f.name);
      out.add(
        PickedDocumentFile(
          bytes: bytes,
          fileName: f.name,
          fileType: type,
        ),
      );
    }
    return out;
  }

  static void _checkSize(int size) {
    if (size <= 0 || size > DocumentImportLimits.fileBytes) {
      throw const FormatException('Choose a nonempty file no larger than 20 MB.');
    }
  }

  static Future<Uint8List> _readBounded(PlatformFile file) async {
    _checkSize(file.size);
    if (file.bytes != null) {
      _checkSize(file.bytes!.length);
      return file.bytes!;
    }
    if (file.path == null) throw const FormatException('The document provider did not supply a readable file.');
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in File(file.path!).openRead()) {
      if (bytes.length + chunk.length > DocumentImportLimits.fileBytes) {
        throw const FormatException('This file exceeds 20 MB.');
      }
      bytes.add(chunk);
    }
    _checkSize(bytes.length);
    return bytes.takeBytes();
  }

  static VaultDocumentFileType _detectTypeFromName(String name) {
    final ext = p.extension(name).toLowerCase();
    if (ext == '.pdf') return VaultDocumentFileType.pdf;
    if (ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.bmp' ||
        ext == '.gif' ||
        ext == '.heic') {
      return VaultDocumentFileType.image;
    }
    return VaultDocumentFileType.other;
  }
}

