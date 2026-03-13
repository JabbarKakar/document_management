enum VaultDocumentFileType {
  image,
  pdf,
  other,
}

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
  });

  final int id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final VaultDocumentFileType fileType;
  final int? categoryId;
  final DateTime? expiryDate;
  final String? notes;
}

