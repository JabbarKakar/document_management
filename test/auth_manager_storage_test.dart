import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/auth/auth_manager.dart';
import 'package:document_management/core/encryption/vault_encryption_service.dart';
import 'package:document_management/core/services/encrypted_file_storage_service.dart';
import 'support/auth_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy PIN verifier migrates only after valid authentication', () async {
    final storage = MemorySecurityStorage()
      ..verifier = sha256.convert(utf8.encode('123456789')).toString();
    final manager = AuthManager(secureStorageService: storage);
    final original = storage.verifier;
    expect(await manager.verifyPin('0000'), isFalse);
    expect(storage.verifier, original);
    expect(await manager.verifyPin('123456789'), isTrue);
    expect(storage.verifier, startsWith('v2\$'));
    expect(await manager.verifyPin('123456789'), isTrue);
    expect(await manager.verifyPin('12345678'), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('vault storage rejects outside paths, uses unique names and enforces lock', () async {
    final directory = await Directory.systemTemp.createTemp('vault_storage_test_');
    final security = MemorySecurityStorage()..encryptionKey = List.filled(32, '01').join();
    var locked = false;
    final storage = EncryptedFileStorageService(directory.path,
      VaultEncryptionService(security), requireUnlocked: () {
        if (locked) throw StateError('Locked');
      });
    try {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final a = await storage.saveBytes(bytes: bytes, fileName: '../../passport.pdf');
      final b = await storage.saveBytes(bytes: bytes, fileName: '../../passport.pdf');
      expect(a, isNot(b));
      expect(File(a).parent.path, directory.path);
      expect(await storage.readDecryptedBytes(a), bytes);
      await expectLater(storage.readDecryptedBytes('${directory.path}/../outside.pdf'), throwsA(isA<FileSystemException>()));
      await expectLater(storage.deleteFile('${directory.path}/../outside.pdf'), throwsA(isA<FileSystemException>()));
      locked = true;
      await expectLater(storage.readDecryptedBytes(a), throwsStateError);
      await expectLater(storage.saveBytes(bytes: bytes, fileName: 'new.pdf'), throwsStateError);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
