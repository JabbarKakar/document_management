class VaultCategory {
  VaultCategory({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final bool isDefault;
  final int sortOrder;
}

