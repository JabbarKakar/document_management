import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:document_management/core/encryption/vault_encryption_service.dart';
import 'package:document_management/core/encryption/password_crypto.dart';
import 'package:document_management/core/services/encrypted_file_storage_service.dart';
import 'package:document_management/core/services/vault_backup_service.dart';
import 'package:document_management/core/services/vault_maintenance_service.dart';
import 'package:document_management/features/categories/data/models/vault_category_model.dart';
import 'package:document_management/features/documents/data/models/vault_document_model.dart';
import 'package:document_management/features/documents/data/repositories/isar_document_repository.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';
import 'support/auth_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final native = Platform.environment['ISAR_TEST_LIBRARY'];
  test(
    'repository preserves versions, trash and encrypted metadata through recovery',
    () async {
      await Isar.initializeIsarCore(libraries: {Abi.windowsX64: native!});
      final root = await Directory.systemTemp.createTemp(
        'vault_repository_test_',
      );
      final targetRoot = await Directory.systemTemp.createTemp(
        'vault_restore_test_',
      );
      Isar? source, target;
      try {
        source = await Isar.open(
          [VaultDocumentModelSchema, VaultCategoryModelSchema],
          directory: root.path,
          name: 'source',
        );
        target = await Isar.open(
          [VaultDocumentModelSchema, VaultCategoryModelSchema],
          directory: targetRoot.path,
          name: 'target',
        );
        EncryptedFileStorageService storage(Directory dir) =>
            EncryptedFileStorageService(
              dir.path,
              VaultEncryptionService(
                MemorySecurityStorage()
                  ..encryptionKey = List.filled(32, '01').join(),
              ),
            );
        final files = storage(root);
        final repo = IsarDocumentRepository(
          isar: source,
          fileStorageService: files,
        );
        Uint8List content(int n) =>
            Uint8List.fromList(utf8.encode('%PDF-1.4\nversion $n\n%%EOF'));
        var doc = await repo.addDocument(
          title: 'Private title',
          notes: 'Personal note',
          fileBytes: content(0),
          originalFileName: 'passport.pdf',
          fileType: VaultDocumentFileType.pdf,
        );
        for (var i = 1; i <= 4; i++) {
          doc = await repo.replaceDocumentFile(
            id: doc.id,
            fileBytes: content(i),
            originalFileName: 'passport.pdf',
            fileType: VaultDocumentFileType.pdf,
          );
        }
        expect(doc.versions, hasLength(3));
        expect(await files.readDecryptedBytes(doc.filePath), content(4));
        final previousPath = doc.versions.last.path;
        doc = await repo.restoreVersion(doc.id, previousPath);
        expect(await files.readDecryptedBytes(doc.filePath), content(1));
        expect(
          await files.readDecryptedBytes(doc.versions.first.path),
          content(4),
        );
        doc = await repo.updateOrganization(
          doc.id,
          favorite: true,
          tags: [' Travel ', 'travel'],
          reminderOffsets: [7, 0],
        );
        final raw = (await source.collection<VaultDocumentModel>().get(
          doc.id,
        ))!;
        expect(raw.title, isEmpty);
        expect(raw.notes, isNull);
        expect(raw.tags, isEmpty);
        expect(raw.encryptedMetadata, isNotNull);
        expect((await repo.getAllDocuments()).single.title, 'Private title');
        final selected = await VaultBackupService(
          isar: source,
          storage: files,
        ).create('portable recovery password', documentIds: {doc.id});
        final selectionManifest = BackupManifest.parse(
          PasswordCrypto.open(selected, 'portable recovery password'),
        );
        expect(selectionManifest.documents, hasLength(1));
        expect(selectionManifest.documents.single.versions, isEmpty);
        expect(selectionManifest.documents.single.activity, isEmpty);
        await repo.deleteDocument(doc);
        expect(await repo.getAllDocuments(), isEmpty);
        expect((await repo.getTrash()).single.versions, hasLength(3));
        final backup = await VaultBackupService(
          isar: source,
          storage: files,
        ).create('portable recovery password');
        final targetFiles = storage(targetRoot);
        await VaultBackupService(
          isar: target,
          storage: targetFiles,
        ).restore(backup, 'portable recovery password');
        final restoredRepo = IsarDocumentRepository(
          isar: target,
          fileStorageService: targetFiles,
        );
        final trash = (await restoredRepo.getTrash()).single;
        expect(trash.title, doc.title);
        expect(trash.tags, ['travel']);
        expect(trash.isFavorite, isTrue);
        expect(trash.versions, hasLength(3));
        expect(
          await targetFiles.readDecryptedBytes(trash.filePath),
          content(1),
        );
        expect(
          (await restoredRepo.restoreDocument(trash.id)).deletedAt,
          isNull,
        );
        await expectLater(
          restoredRepo.permanentlyDeleteDocument(trash.id),
          throwsStateError,
        );
        final report = await VaultMaintenanceService(
          target,
          targetFiles,
        ).upgradeAndVerify();
        expect(report.failedIds, isEmpty);
        expect(report.completed, 1);
        await restoredRepo.deleteDocument(
          (await restoredRepo.getAllDocuments()).single,
        );
        await restoredRepo.permanentlyDeleteDocument(trash.id);
        expect(await restoredRepo.getTrash(), isEmpty);
        expect(await File(trash.filePath).exists(), isFalse);
        for (final version in trash.versions) {
          expect(await File(version.path).exists(), isFalse);
        }

        final legacyPath = '${targetRoot.path}/old-plaintext.pdf';
        await File(legacyPath).writeAsBytes(content(9));
        final legacy = VaultDocumentModel()
          ..title = 'Legacy title'
          ..notes = 'Old notes'
          ..filePath = legacyPath
          ..createdAt = DateTime(2020)
          ..fileType = VaultDocumentFileType.pdf;
        final missing = VaultDocumentModel()
          ..title = 'Missing file'
          ..filePath = '${targetRoot.path}/missing.pdf'
          ..createdAt = DateTime(2020)
          ..fileType = VaultDocumentFileType.pdf;
        await target.writeTxn(() async {
          legacy.id = await target!.collection<VaultDocumentModel>().put(
            legacy,
          );
          missing.id = await target!.collection<VaultDocumentModel>().put(
            missing,
          );
        });
        final maintenance = VaultMaintenanceService(target, targetFiles);
        final upgraded = await maintenance.upgradeAndVerify();
        expect(upgraded.completed, 1);
        expect(upgraded.failedIds, [missing.id]);
        final migrated = (await target.collection<VaultDocumentModel>().get(
          legacy.id,
        ))!;
        expect(migrated.encryptedMetadata, isNotNull);
        expect(migrated.title, isEmpty);
        expect(await File(legacyPath).exists(), isFalse);
        expect(
          await targetFiles.readDecryptedBytes(migrated.filePath),
          content(9),
        );
        expect(
          await target.collection<VaultDocumentModel>().get(missing.id),
          isNotNull,
        );
        final orphan = await targetFiles.saveBytes(
          bytes: content(8),
          fileName: 'orphan.pdf',
        );
        await File(
          orphan,
        ).setLastModified(DateTime.now().subtract(const Duration(days: 2)));
        await File(
          migrated.filePath,
        ).setLastModified(DateTime.now().subtract(const Duration(days: 2)));
        expect(await maintenance.findCleanupCandidates(), [orphan]);
        expect(await maintenance.cleanupUnreferencedFiles(), 1);
        expect(await File(migrated.filePath).exists(), isTrue);
      } finally {
        await source?.close();
        await target?.close();
        await root.delete(recursive: true);
        await targetRoot.delete(recursive: true);
      }
    },
    skip: native == null
        ? 'Set ISAR_TEST_LIBRARY to the Isar 3.1 Windows DLL.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
