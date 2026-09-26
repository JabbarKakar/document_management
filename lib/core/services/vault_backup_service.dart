import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import '../../features/categories/data/models/vault_category_model.dart';
import '../../features/documents/data/models/vault_document_model.dart';
import '../../features/documents/domain/entities/vault_document.dart';
import '../../features/documents/domain/document_history.dart';
import '../encryption/password_crypto.dart';
import 'encrypted_file_storage_service.dart';
import 'document_metadata_codec.dart';

Uint8List _sealBackup((Uint8List, String) input) =>
    PasswordCrypto.seal(input.$1, input.$2);
Uint8List _openBackup((Uint8List, String) input) =>
    PasswordCrypto.open(input.$1, input.$2);

/// Portable logical backup, independent of Isar files, paths, device keys or PIN.
/// The entire manifest and file contents are encrypted with the recovery password.
class VaultBackupService {
  VaultBackupService({required this.isar, required this.storage});
  final Isar isar;
  final EncryptedFileStorageService storage;
  static const maxContentBytes = 32 * 1024 * 1024;
  static const maxPackageBytes = 48 * 1024 * 1024;
  static const maxDocuments = 1000;
  bool _busy = false;

  static String? validatePassword(String password) =>
      password.length >= 12 && password.trim().length >= 12
      ? null
      : 'Use a recovery password of at least 12 characters.';

  Future<Uint8List> create(String password, {Set<int>? documentIds}) async {
    final error = validatePassword(password);
    if (error != null) throw FormatException(error);
    if (_busy) throw StateError('Another recovery operation is running.');
    _busy = true;
    try {
      storage.requireUnlocked?.call();
      final allDocuments = await isar
          .collection<VaultDocumentModel>()
          .where()
          .findAll();
      final documents = documentIds == null
          ? allDocuments
          : allDocuments
                .where((d) => documentIds.contains(d.id) && d.deletedAt == null)
                .toList();
      if (documentIds != null &&
          (documentIds.isEmpty || documents.length != documentIds.length)) {
        throw const FormatException(
          'Some selected documents are no longer available. Refresh and retry.',
        );
      }
      final allCategories = await isar
          .collection<VaultCategoryModel>()
          .where()
          .findAll();
      final usedCategories = documents.map((d) => d.categoryId).toSet();
      final categories = documentIds == null
          ? allCategories
          : allCategories.where((c) => usedCategories.contains(c.id)).toList();
      if (documents.length > maxDocuments) {
        throw const FormatException(
          'This backup supports up to 1,000 documents.',
        );
      }
      var size = 0;
      Future<Map<String, Object?>> content(String path) async {
        if (await storage.storedLength(path) > maxContentBytes - size + 64) {
          throw const FormatException(
            'Backup content, including versions, exceeds 32 MB.',
          );
        }
        final bytes = await storage.readDecryptedBytes(path);
        size += bytes.length;
        if (size > maxContentBytes) {
          throw const FormatException(
            'Backup content, including versions, exceeds 32 MB.',
          );
        }
        return {'extension': p.extension(path), 'bytes': base64Encode(bytes)};
      }

      final records = <Map<String, Object?>>[];
      for (final stored in documents) {
        final doc = await DocumentMetadataCodec(storage).decode(stored);
        final versions = <Map<String, Object?>>[];
        for (final version
            in (documentIds == null ? doc.versionRecords : <String>[]).map(
              DocumentVersion.decode,
            )) {
          versions.add({
            ...await content(version.path),
            'fileType': VaultDocumentFileType.values[version.typeIndex].name,
            'createdAt': version.createdAt.toIso8601String(),
          });
        }
        records.add({
          ...await content(doc.filePath),
          'title': doc.title,
          'createdAt': doc.createdAt.toIso8601String(),
          'expiryDate': doc.expiryDate?.toIso8601String(),
          'notes': doc.notes,
          'categoryId': doc.categoryId,
          'fileType': doc.fileType.name,
          'updatedAt': doc.updatedAt?.toIso8601String(),
          'deletedAt': doc.deletedAt?.toIso8601String(),
          'isFavorite': doc.isFavorite,
          'tags': doc.tags,
          'reminderOffsets': doc.reminderOffsets,
          'remindersDisabled': doc.remindersDisabled,
          'extractedText': doc.extractedText,
          'activity': documentIds == null ? doc.activityRecords : <String>[],
          'versions': versions,
        });
      }
      final plain = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'version': 2,
            'categories': categories
                .map(
                  (c) => {
                    'id': c.id,
                    'name': c.name,
                    'isDefault': c.isDefault,
                    'sortOrder': c.sortOrder,
                  },
                )
                .toList(),
            'documents': records,
          }),
        ),
      );
      if (plain.length > maxPackageBytes - 52) {
        throw const FormatException(
          'Backup metadata exceeds the supported size.',
        );
      }
      BackupManifest.parse(plain);
      final package = await compute(_sealBackup, (plain, password));
      storage.requireUnlocked?.call();
      return package;
    } finally {
      _busy = false;
    }
  }

  Future<int> restore(Uint8List package, String password) async {
    if (_busy) throw StateError('Another recovery operation is running.');
    if (package.length > maxPackageBytes) {
      throw const FormatException('Backup exceeds 48 MB.');
    }
    _busy = true;
    final stagedPaths = <String>[];
    var committed = false;
    try {
      storage.requireUnlocked?.call();
      if (await isar.collection<VaultDocumentModel>().count() != 0) {
        throw const FormatException(
          'Restore requires an empty vault. Existing documents will not be overwritten.',
        );
      }
      final plain = await compute(_openBackup, (package, password));
      final manifest = BackupManifest.parse(plain);
      final models = <VaultDocumentModel>[];
      for (final doc in manifest.documents) {
        final path = await storage.saveBytes(
          bytes: doc.bytes,
          fileName: 'restored${doc.extension}',
        );
        stagedPaths.add(path);
        final versions = <String>[];
        for (final version in doc.versions) {
          final versionPath = await storage.saveBytes(
            bytes: version.bytes,
            fileName: 'restored${version.extension}',
          );
          stagedPaths.add(versionPath);
          versions.add(
            DocumentVersion(
              path: versionPath,
              typeIndex: version.fileType.index,
              createdAt: version.createdAt,
            ).encode(),
          );
        }
        models.add(
          VaultDocumentModel()
            ..title = doc.title
            ..filePath = path
            ..createdAt = doc.createdAt
            ..fileType = doc.fileType
            ..expiryDate = doc.expiryDate
            ..notes = doc.notes
            ..categoryId = doc.categoryId
            ..updatedAt = doc.updatedAt
            // Recovery grants trashed content a fresh recovery window.
            ..deletedAt = doc.deletedAt == null ? null : DateTime.now()
            ..isFavorite = doc.isFavorite
            ..tags = doc.tags
            ..versionRecords = versions
            ..activityRecords = doc.activity
            ..extractedText = doc.extractedText
            ..reminderOffsets = doc.reminderOffsets
            ..remindersDisabled = doc.remindersDisabled,
        );
      }
      await isar.writeTxn(() async {
        storage.requireUnlocked?.call();
        final documentCollection = isar.collection<VaultDocumentModel>();
        if (await documentCollection.count() != 0) {
          throw const FormatException(
            'The vault changed during restore. No documents were restored.',
          );
        }
        final categoryCollection = isar.collection<VaultCategoryModel>();
        final existing = await categoryCollection.where().findAll();
        final byName = {for (final c in existing) c.name.toLowerCase(): c.id};
        final mapping = <int, int>{};
        final reusedIds = <int>{};
        for (final category in manifest.categories) {
          var id = byName[category.name.toLowerCase()];
          if (id != null && !reusedIds.add(id)) id = null;
          id ??= await categoryCollection.put(
            VaultCategoryModel()
              ..name = category.name
              ..isDefault = category.isDefault
              ..sortOrder = category.sortOrder,
          );
          mapping[category.id] = id;
        }
        for (final model in models) {
          model.categoryId = mapping[model.categoryId];
        }
        final encoded = <VaultDocumentModel>[];
        for (final model in models) {
          encoded.add(await DocumentMetadataCodec(storage).encode(model));
        }
        await documentCollection.putAll(encoded);
      });
      committed = true;
      return models.length;
    } finally {
      if (!committed) {
        for (final path in stagedPaths) {
          try {
            await storage.deleteFile(path);
          } catch (_) {
            /* Safe orphan. */
          }
        }
      }
      _busy = false;
    }
  }
}

class BackupDocument {
  BackupDocument(
    this.title,
    this.createdAt,
    this.expiryDate,
    this.notes,
    this.categoryId,
    this.fileType,
    this.extension,
    this.bytes, {
    this.updatedAt,
    this.deletedAt,
    this.isFavorite = false,
    this.tags = const [],
    this.reminderOffsets = const [],
    this.remindersDisabled = false,
    this.extractedText,
    this.activity = const [],
    this.versions = const [],
  });
  final String title;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final String? notes;
  final int? categoryId;
  final VaultDocumentFileType fileType;
  final String extension;
  final Uint8List bytes;
  final DateTime? updatedAt, deletedAt;
  final bool isFavorite, remindersDisabled;
  final List<String> tags, activity;
  final List<int> reminderOffsets;
  final String? extractedText;
  final List<BackupDocument> versions;
}

class BackupCategory {
  BackupCategory(this.id, this.name, this.isDefault, this.sortOrder);
  final int id;
  final String name;
  final bool isDefault;
  final int sortOrder;
}

/// Validate the whole package before writing any files or database rows.
class BackupManifest {
  BackupManifest(this.documents, this.categories);
  final List<BackupDocument> documents;
  final List<BackupCategory> categories;

  static BackupManifest parse(Uint8List plain) {
    try {
      if (plain.length > VaultBackupService.maxPackageBytes) {
        throw const FormatException();
      }
      final data = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      if (data['version'] != 1 && data['version'] != 2) {
        throw const FormatException();
      }
      final categoryData = data['categories'] as List;
      final documentData = data['documents'] as List;
      if (categoryData.length > 1000 ||
          documentData.length > VaultBackupService.maxDocuments) {
        throw const FormatException();
      }
      final categoryIds = <int>{};
      final categories = categoryData.map((raw) {
        final c = raw as Map<String, dynamic>;
        final id = c['id'] as int;
        if (id <= 0 || !categoryIds.add(id)) throw const FormatException();
        return BackupCategory(
          id,
          _text(c['name'], 4096),
          c['isDefault'] as bool,
          c['sortOrder'] as int,
        );
      }).toList();
      var total = 0;
      BackupDocument parseDocument(dynamic raw, {bool version = false}) {
        final d = raw as Map<String, dynamic>;
        final bytes = base64Decode(d['bytes'] as String);
        total += bytes.length;
        if (bytes.isEmpty || total > VaultBackupService.maxContentBytes) {
          throw const FormatException();
        }
        final extension = _text(d['extension'], 10, allowEmpty: true);
        if (!RegExp(r'^(\.[a-zA-Z0-9]{1,9})?$').hasMatch(extension)) {
          throw const FormatException();
        }
        final category = d['categoryId'] as int?;
        if (category != null && !categoryIds.contains(category)) {
          throw const FormatException();
        }
        final tags = (d['tags'] as List? ?? [])
            .map((v) => _text(v, 40))
            .toList();
        final offsets = (d['reminderOffsets'] as List? ?? []).cast<int>();
        final activity = (d['activity'] as List? ?? []).map((v) {
          final encoded = _text(v, 4096);
          final event = DocumentActivity.decode(encoded);
          _text(event.action, 1024);
          return encoded;
        }).toList();
        final versions = d['versions'] as List? ?? [];
        if (tags.length > 20 ||
            offsets.length > 5 ||
            offsets.any((d) => d < 0 || d > 365) ||
            activity.length > 200 ||
            versions.length > VaultRetention.previousVersions ||
            (version && versions.isNotEmpty)) {
          throw const FormatException();
        }
        return BackupDocument(
          version ? 'Previous version' : _text(d['title'], 4096),
          DateTime.parse(d['createdAt'] as String),
          d['expiryDate'] == null
              ? null
              : DateTime.parse(d['expiryDate'] as String),
          d['notes'] == null
              ? null
              : _text(d['notes'], 1024 * 1024, allowEmpty: true),
          category,
          VaultDocumentFileType.values.byName(d['fileType'] as String),
          extension,
          bytes,
          updatedAt: d['updatedAt'] == null
              ? null
              : DateTime.parse(d['updatedAt'] as String),
          deletedAt: d['deletedAt'] == null
              ? null
              : DateTime.parse(d['deletedAt'] as String),
          isFavorite: d['isFavorite'] as bool? ?? false,
          tags: tags,
          reminderOffsets: offsets,
          remindersDisabled: d['remindersDisabled'] as bool? ?? false,
          extractedText: d['extractedText'] == null
              ? null
              : _text(d['extractedText'], 1024 * 1024, allowEmpty: true),
          activity: activity,
          versions: versions
              .map((v) => parseDocument(v, version: true))
              .toList(),
        );
      }

      final documents = documentData.map((d) => parseDocument(d)).toList();
      return BackupManifest(documents, categories);
    } catch (_) {
      throw const FormatException(
        'Invalid or unsupported backup contents. Nothing was restored.',
      );
    }
  }

  static String _text(Object? value, int max, {bool allowEmpty = false}) {
    final text = value as String;
    if (text.length > max || (!allowEmpty && text.trim().isEmpty)) {
      throw const FormatException();
    }
    return text;
  }
}
