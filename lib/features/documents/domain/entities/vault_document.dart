import '../document_history.dart';

enum VaultDocumentFileType { image, pdf, other }

class VaultDocument {
  VaultDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.fileType,
    this.categoryId,
    this.expiryDate,
    this.notes,
    this.updatedAt,
    this.deletedAt,
    this.isFavorite = false,
    this.tags = const [],
    this.versions = const [],
    this.activity = const [],
    this.extractedText,
    this.reminderOffsets = const [],
    this.remindersDisabled = false,
  });

  final int id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final VaultDocumentFileType fileType;
  final int? categoryId;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isFavorite;
  final List<String> tags;
  final List<DocumentVersion> versions;
  final List<DocumentActivity> activity;
  final String? extractedText;
  final List<int> reminderOffsets;
  final bool remindersDisabled;
}
