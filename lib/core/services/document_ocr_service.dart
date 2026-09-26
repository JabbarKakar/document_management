import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfx/pdfx.dart';
import '../../features/documents/domain/entities/vault_document.dart';
import 'encrypted_file_storage_service.dart';

/// Explicit on-device OCR. No document image is written to a temporary file.
class DocumentOcrService {
  DocumentOcrService(this.storage, {MethodChannel? channel})
    : channel = channel ?? const MethodChannel('document_vault/offline_ocr');
  final EncryptedFileStorageService storage;
  final MethodChannel channel;

  Future<String> extract(
    VaultDocument document, {
    bool Function()? isCancelled,
    void Function(int, int)? onProgress,
  }) async {
    void check() {
      storage.requireUnlocked?.call();
      if (isCancelled?.call() == true) {
        throw StateError('Text extraction cancelled.');
      }
    }

    Future<String> recognize(Uint8List image) async {
      check();
      final text =
          await channel.invokeMethod<String>('recognize', {'bytes': image}) ??
          '';
      check();
      return text;
    }

    check();
    final bytes = await storage.readDecryptedBytes(document.filePath);
    if (bytes.length > 20 * 1024 * 1024) {
      throw const FormatException(
        'Text extraction supports files up to 20 MB.',
      );
    }
    if (document.fileType == VaultDocumentFileType.image) {
      final normalized = await compute(_normalizeImage, bytes);
      final text = await recognize(normalized);
      if (text.length > 1024 * 1024) {
        throw const FormatException(
          'Extracted text exceeds the supported size.',
        );
      }
      onProgress?.call(1, 1);
      return text;
    }
    if (document.fileType != VaultDocumentFileType.pdf) {
      throw const FormatException(
        'Choose an image or PDF for text extraction.',
      );
    }
    final pdf = await PdfDocument.openData(bytes);
    try {
      if (pdf.pagesCount > 20) {
        throw const FormatException(
          'Text extraction supports PDFs up to 20 pages. Split this PDF first.',
        );
      }
      final result = StringBuffer();
      for (var i = 1; i <= pdf.pagesCount; i++) {
        check();
        final page = await pdf.getPage(i);
        try {
          final edge = page.width > page.height ? page.width : page.height;
          final scale = 1800 / edge;
          final rendered = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (rendered == null) {
            throw const FormatException('A PDF page could not be rendered.');
          }
          result.writeln(await recognize(rendered.bytes));
          if (result.length > 1024 * 1024) {
            throw const FormatException(
              'Extracted text exceeds the supported size.',
            );
          }
        } finally {
          await page.close();
        }
        onProgress?.call(i, pdf.pagesCount);
      }
      return result.toString().trim();
    } finally {
      await pdf.close();
    }
  }
}

Uint8List _normalizeImage(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  if (decoder == null) return bytes;
  final info = decoder.startDecode(bytes);
  if (info == null || info.width * info.height > 40000000) {
    throw const FormatException('Choose an image up to 40 megapixels.');
  }
  final first = decoder.decodeFrame(0);
  if (first == null) {
    throw const FormatException('The image could not be decoded.');
  }
  var normalized = img.bakeOrientation(first);
  if (normalized.width > 2400 || normalized.height > 2400) {
    normalized = img.copyResize(
      normalized,
      width: normalized.width >= normalized.height ? 2400 : null,
      height: normalized.height > normalized.width ? 2400 : null,
    );
  }
  return img.encodeJpg(normalized, quality: 92);
}
