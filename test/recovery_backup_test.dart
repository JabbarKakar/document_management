import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/encryption/password_crypto.dart';
import 'package:document_management/core/services/vault_backup_service.dart';

Map<String, Object?> fixture() => {
  'version': 1,
  'categories': [
    {'id': 1, 'name': 'Travel', 'isDefault': false, 'sortOrder': 0},
  ],
  'documents': [
    <String, Object?>{
      'title': 'Passport',
      'createdAt': '2026-09-25T09:00:00.000',
      'expiryDate': '2030-09-25T00:00:00.000',
      'notes': 'Private note',
      'categoryId': 1,
      'fileType': 'pdf',
      'extension': '.pdf',
      'bytes': base64Encode(utf8.encode('%PDF-1.4 test document')),
    },
  ],
};
Uint8List encode(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

void main() {
  test(
    'portable encrypted backup round-trips content and metadata without device keys',
    () {
      final plain = encode(fixture());
      final package = PasswordCrypto.seal(
        plain,
        'a separate recovery password',
      );
      expect(
        utf8.decode(package, allowMalformed: true),
        isNot(contains('Passport')),
      );
      final restored = BackupManifest.parse(
        PasswordCrypto.open(package, 'a separate recovery password'),
      );
      expect(restored.categories.single.name, 'Travel');
      expect(restored.documents.single.title, 'Passport');
      expect(restored.documents.single.notes, 'Private note');
      expect(
        utf8.decode(restored.documents.single.bytes),
        '%PDF-1.4 test document',
      );
      expect(
        () => PasswordCrypto.open(package, 'an incorrect recovery password'),
        throwsFormatException,
      );
      package[package.length - 1] ^= 1;
      expect(
        () => PasswordCrypto.open(package, 'a separate recovery password'),
        throwsFormatException,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'manifest rejects traversal, invalid category references and unsupported versions',
    () {
      final traversal = fixture();
      (traversal['documents'] as List).single['extension'] = '/../secret';
      expect(
        () => BackupManifest.parse(encode(traversal)),
        throwsFormatException,
      );
      final dangling = fixture();
      (dangling['documents'] as List).single['categoryId'] = 99;
      expect(
        () => BackupManifest.parse(encode(dangling)),
        throwsFormatException,
      );
      final unsupported = fixture()..['version'] = 99;
      expect(
        () => BackupManifest.parse(encode(unsupported)),
        throwsFormatException,
      );
    },
  );
  test('short or malformed backup headers fail before password derivation', () {
    expect(
      () => PasswordCrypto.open(Uint8List(0), 'password'),
      throwsFormatException,
    );
    expect(
      () => PasswordCrypto.open(Uint8List(100), 'password'),
      throwsFormatException,
    );
  });

  test('v2 retains organization, trash and portable previous versions', () {
    final data = fixture()..['version'] = 2;
    final doc = (data['documents'] as List).single as Map<String, Object?>;
    doc.addAll({
      'isFavorite': true,
      'tags': ['travel'],
      'reminderOffsets': [45, 3, 0],
      'remindersDisabled': true,
      'extractedText': 'Searchable scan',
      'deletedAt': '2026-09-20T00:00:00.000',
      'activity': [
        jsonEncode({
          'action': 'Moved to Trash',
          'at': '2026-09-20T00:00:00.000',
        }),
      ],
      'versions': [
        <String, Object?>{
          'fileType': 'image',
          'extension': '.jpg',
          'createdAt': '2026-09-01T00:00:00.000',
          'bytes': base64Encode([1, 2, 3]),
        },
      ],
    });
    final restored = BackupManifest.parse(encode(data)).documents.single;
    expect(restored.isFavorite, isTrue);
    expect(restored.tags, ['travel']);
    expect(restored.reminderOffsets, [45, 3, 0]);
    expect(restored.remindersDisabled, isTrue);
    expect(restored.deletedAt, DateTime(2026, 9, 20));
    expect(restored.extractedText, 'Searchable scan');
    expect(restored.activity, hasLength(1));
    expect(restored.versions.single.bytes, [1, 2, 3]);

    final version = (doc['versions'] as List).single;
    version['versions'] = [Map<String, Object?>.from(version)];
    expect(() => BackupManifest.parse(encode(data)), throwsFormatException);
    version.remove('versions');
    doc['reminderOffsets'] = [-1];
    expect(() => BackupManifest.parse(encode(data)), throwsFormatException);
  });
}
