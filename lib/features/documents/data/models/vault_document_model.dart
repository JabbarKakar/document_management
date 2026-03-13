import 'package:isar/isar.dart';

import '../../domain/entities/vault_document.dart';

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
      ..fileType = entity.fileType;
    return model;
  }
}

