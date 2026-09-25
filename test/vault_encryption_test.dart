import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/encryption/vault_encryption_service.dart';
import 'package:document_management/core/services/encrypted_file_storage_service.dart';
import 'package:document_management/core/services/document_metadata_codec.dart';
import 'package:document_management/features/documents/data/models/vault_document_model.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';
import 'support/auth_fakes.dart';

void main() {
  final key = Uint8List.fromList(List.filled(32, 1));
  VaultEncryptionService encryption() => VaultEncryptionService(MemorySecurityStorage()
    ..encryptionKey = List.filled(32, '01').join());

  test('authenticated files reject modified header, nonce, ciphertext and tag', () async {
    final service = encryption();
    final plain = Uint8List.fromList(utf8.encode('Private document content'));
    final sealed = await service.encryptDocumentBytes(plain);
    expect(await service.decryptDocumentBytes(sealed), plain);
    expect(await service.encryptDocumentBytes(plain), isNot(sealed));
    for (final index in [0, 10, 22, sealed.length - 1]) {
      final corrupted = Uint8List.fromList(sealed)..[index] ^= 1;
      await expectLater(service.decryptDocumentBytes(corrupted), throwsFormatException);
    }
    await expectLater(service.decryptDocumentBytes(Uint8List.fromList(utf8.encode('%PDF-1.4 plaintext'))), throwsFormatException);
  });

  test('legacy CBC remains readable and upgrades without removing the original', () async {
    final directory = await Directory.systemTemp.createTemp('vault_upgrade_test_');
    try {
      final service = encryption();
      final storage = EncryptedFileStorageService(directory.path, service);
      final plain = Uint8List.fromList(utf8.encode('%PDF-1.4 legacy document'));
      final iv = enc.IV.fromSecureRandom(16);
      final cipher = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc)).encryptBytes(plain, iv: iv);
      final old = File('${directory.path}/legacy.pdf');
      await old.writeAsBytes([...utf8.encode('DM_ENC_v1'), ...iv.bytes, ...cipher.bytes]);
      expect(await storage.readDecryptedBytes(old.path), plain);
      final upgraded = (await storage.stageAuthenticatedUpgrade(old.path))!;
      expect(await old.exists(), isTrue);
      expect(await storage.readDecryptedBytes(upgraded), plain);
      expect(await storage.stageAuthenticatedUpgrade(upgraded), isNull);
      final raw = await File(upgraded).readAsBytes();
      raw[8] = '1'.codeUnitAt(0);
      await File(upgraded).writeAsBytes(raw);
      await expectLater(storage.readDecryptedBytes(upgraded), throwsFormatException);
    } finally { await directory.delete(recursive: true); }
  });

  test('metadata is sealed without mutating source and bound to its document file', () async {
    final storage = EncryptedFileStorageService('unused', encryption());
    final codec = DocumentMetadataCodec(storage);
    final source = VaultDocumentModel()..title = 'Private title'..filePath = 'v2_random.pdf'
      ..createdAt = DateTime(2026)..fileType = VaultDocumentFileType.pdf
      ..notes = 'Sensitive notes'..tags = ['personal']..extractedText = 'Secret scan text';
    final encoded = await codec.encode(source);
    expect(source.title, 'Private title');
    expect(encoded.title, isEmpty);
    expect(encoded.notes, isNull);
    expect(encoded.tags, isEmpty);
    expect(encoded.extractedText, isNull);
    final decoded = await codec.decode(encoded);
    expect(decoded.title, source.title);
    expect(decoded.tags, source.tags);
    expect(decoded.extractedText, source.extractedText);
    encoded.filePath = 'another.pdf';
    await expectLater(codec.decode(encoded), throwsFormatException);
  });
}
