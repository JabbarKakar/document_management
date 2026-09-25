import 'package:isar/isar.dart';

import '../../domain/entities/vault_document.dart';
import '../../domain/document_history.dart';

part 'vault_document_model.g.dart';

@collection
class VaultDocumentModel {
  VaultDocumentModel();

  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String title;
  late String filePath;
  @Index()
  late DateTime createdAt;

  @Index()
  int? categoryId;
  DateTime? expiryDate;
  @Index(caseSensitive: false)
  String? notes;

  DateTime? updatedAt;
  @Index()
  DateTime? deletedAt;
  bool isFavorite = false;
  List<String> tags = [];
  List<String> versionRecords = [];
  List<String> activityRecords = [];
  String? extractedText;
  List<int> reminderOffsets = [];
  bool remindersDisabled = false;
  String? encryptedMetadata;

  @enumerated
  late VaultDocumentFileType fileType;

  VaultDocument toEntity() {
    return VaultDocument(
      id: id,
      title: title,
      filePath: filePath,
      createdAt: createdAt,
      fileType: fileType,
      categoryId: categoryId,
      expiryDate: expiryDate,
      notes: notes,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      isFavorite: isFavorite,
      tags: List.unmodifiable(tags),
      versions: versionRecords.map(DocumentVersion.decode).toList(),
      activity: activityRecords.map(DocumentActivity.decode).toList(),
      extractedText: extractedText,
      reminderOffsets: List.unmodifiable(reminderOffsets),
      remindersDisabled: remindersDisabled,
    );
  }

  static VaultDocumentModel fromEntity(VaultDocument entity) {
    final model = VaultDocumentModel()
      ..id = entity.id
      ..title = entity.title
      ..filePath = entity.filePath
      ..createdAt = entity.createdAt
      ..categoryId = entity.categoryId
      ..expiryDate = entity.expiryDate
      ..notes = entity.notes
      ..fileType = entity.fileType
      ..updatedAt = entity.updatedAt
      ..deletedAt = entity.deletedAt
      ..isFavorite = entity.isFavorite
      ..tags = entity.tags.toList()
      ..versionRecords = entity.versions.map((v) => v.encode()).toList()
      ..activityRecords = entity.activity.map((a) => a.encode()).toList()
      ..extractedText = entity.extractedText
      ..reminderOffsets = entity.reminderOffsets.toList()
      ..remindersDisabled = entity.remindersDisabled;
    return model;
  }
}
