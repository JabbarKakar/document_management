import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;
import '../../domain/entities/vault_document.dart';

abstract final class DocumentImportLimits {
  static const fileBytes = 20 * 1024 * 1024;
  static const batchBytes = 64 * 1024 * 1024;
  static const batchFiles = 50;
  static const imagePixels = 40 * 1000 * 1000;
}

Future<void> validateDocumentImport(Uint8List bytes, String name, VaultDocumentFileType type) =>
    compute(_validate, (bytes, name, type));

void _validate((Uint8List, String, VaultDocumentFileType) input) {
  final (bytes, name, type) = input;
  if (bytes.isEmpty || bytes.length > DocumentImportLimits.fileBytes) {
    throw const FormatException('Choose a nonempty file no larger than 20 MB.');
  }
  final ext = p.extension(name).toLowerCase();
  final header = latin1.decode(bytes.take(12).toList());
  if (type == VaultDocumentFileType.pdf) {
    final tail = latin1.decode(bytes.sublist(bytes.length > 2048 ? bytes.length - 2048 : 0));
    if (ext != '.pdf' || !header.startsWith('%PDF-') || !tail.contains('%%EOF')) {
      throw const FormatException('This file is not a complete PDF.');
    }
    return;
  }
  if (type != VaultDocumentFileType.image) {
    throw const FormatException('Choose a PDF or supported image.');
  }
  // HEIC/HEIF decoding is platform-dependent. Keep existing import support,
  // checking its ISO-BMFF brand; other formats get dimension validation too.
  if (ext == '.heic' || ext == '.heif') {
    if (header.length < 12 || header.substring(4, 8) != 'ftyp' ||
        !['heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'].contains(header.substring(8, 12))) {
      throw const FormatException('The image contents do not match its file type.');
    }
    return;
  }
  final matches = switch (ext) {
    '.jpg' || '.jpeg' => header.startsWith('\u00ff\u00d8\u00ff'),
    '.png' => header.startsWith('\u0089PNG\r\n\u001a\n'),
    '.gif' => header.startsWith('GIF87a') || header.startsWith('GIF89a'),
    '.bmp' => header.startsWith('BM'),
    '.webp' => header.startsWith('RIFF') && header.endsWith('WEBP'),
    _ => false,
  };
  if (!matches) throw const FormatException('The image contents do not match its file type.');
  try {
    final decoder = image.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0 ||
        info.width * info.height > DocumentImportLimits.imagePixels || info.numFrames > 100) {
      throw const FormatException('Use an image up to 40 megapixels and 100 frames.');
    }
  } on FormatException { rethrow; }
  catch (_) { throw const FormatException('This image is damaged or unsupported.'); }
}
