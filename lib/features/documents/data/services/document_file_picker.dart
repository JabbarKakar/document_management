import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/vault_document.dart';

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
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return null;

    return PickedDocumentFile(
      bytes: file.bytes!,
      fileName: file.name,
      fileType: VaultDocumentFileType.pdf,
    );
  }
}

