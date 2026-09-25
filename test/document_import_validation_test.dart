import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:document_management/features/documents/data/services/document_import_validation.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';

void main() {
  test('import rejects extension spoofing and truncated PDFs', () async {
    final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4\n1 0 obj\nendobj\n%%EOF'));
    await validateDocumentImport(pdf, 'valid.pdf', VaultDocumentFileType.pdf);
    await expectLater(validateDocumentImport(pdf, 'fake.jpg', VaultDocumentFileType.image), throwsFormatException);
    await expectLater(validateDocumentImport(Uint8List.fromList(utf8.encode('%PDF-1.4 broken')), 'broken.pdf', VaultDocumentFileType.pdf), throwsFormatException);
    await expectLater(validateDocumentImport(Uint8List(0), 'empty.pdf', VaultDocumentFileType.pdf), throwsFormatException);
  });
  test('image import checks dimensions before pixel decoding', () async {
    final png = image.encodePng(image.Image(width: 4, height: 4));
    await validateDocumentImport(png, 'small.png', VaultDocumentFileType.image);
    final oversized = Uint8List.fromList(png);
    // PNG IHDR width/height fields; no large bitmap allocation in this test.
    ByteData.sublistView(oversized).setUint32(16, 100000);
    ByteData.sublistView(oversized).setUint32(20, 100000);
    await expectLater(validateDocumentImport(oversized, 'oversized.png', VaultDocumentFileType.image), throwsFormatException);
  });
}
