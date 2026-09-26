import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:document_management/core/encryption/vault_encryption_service.dart';
import 'package:document_management/core/services/document_ocr_service.dart';
import 'package:document_management/core/services/encrypted_file_storage_service.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';
import 'support/auth_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('document_vault/offline_ocr');
  test(
    'OCR uses in-memory images and discards results when vault locks',
    () async {
      final root = await Directory.systemTemp.createTemp('vault_ocr_test_');
      var locked = false;
      final storage = EncryptedFileStorageService(
        root.path,
        VaultEncryptionService(
          MemorySecurityStorage()..encryptionKey = List.filled(32, '01').join(),
        ),
        requireUnlocked: () {
          if (locked) throw StateError('Locked');
        },
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      try {
        final path = await storage.saveBytes(
          bytes: img.encodePng(img.Image(width: 20, height: 10)),
          fileName: 'scan.png',
        );
        final doc = VaultDocument(
          id: 1,
          title: 'Scan',
          filePath: path,
          createdAt: DateTime.now(),
          fileType: VaultDocumentFileType.image,
        );
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'recognize');
          expect((call.arguments as Map).keys, ['bytes']);
          return 'Recognized text';
        });
        expect(
          await DocumentOcrService(storage).extract(doc),
          'Recognized text',
        );
        messenger.setMockMethodCallHandler(channel, (call) async {
          locked = true;
          return 'Late result';
        });
        await expectLater(
          DocumentOcrService(storage).extract(doc),
          throwsStateError,
        );
        expect((await root.list().toList()).length, 1);
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
        await root.delete(recursive: true);
      }
    },
  );
}
