import 'dart:convert';

class DocumentVersion {
  const DocumentVersion({
    required this.path,
    required this.typeIndex,
    required this.createdAt,
  });
  final String path;
  final int typeIndex;
  final DateTime createdAt;
  Map<String, Object?> toMap() => {
    'path': path,
    'type': typeIndex,
    'createdAt': createdAt.toIso8601String(),
  };
  String encode() => jsonEncode(toMap());
  factory DocumentVersion.decode(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    return DocumentVersion(
      path: data['path'] as String,
      typeIndex: data['type'] as int,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}

class DocumentActivity {
  const DocumentActivity(this.action, this.at);
  final String action;
  final DateTime at;
  String encode() => jsonEncode({'action': action, 'at': at.toIso8601String()});
  factory DocumentActivity.decode(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    return DocumentActivity(
      data['action'] as String,
      DateTime.parse(data['at'] as String),
    );
  }
}

abstract final class VaultRetention {
  static const trashDays = 30;
  static const previousVersions = 3;
  static bool shouldPurge(DateTime deletedAt, DateTime now) =>
      !now.isBefore(deletedAt.add(const Duration(days: trashDays)));
}
