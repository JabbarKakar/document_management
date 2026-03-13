import 'package:isar/isar.dart';

import '../../domain/entities/vault_category.dart';

part 'vault_category_model.g.dart';

@collection
class VaultCategoryModel {
  VaultCategoryModel();

  Id id = Isar.autoIncrement;

  late String name;
  @Index()
  late bool isDefault;
  @Index()
  late int sortOrder;

  VaultCategory toEntity() {
    return VaultCategory(
      id: id,
      name: name,
      isDefault: isDefault,
      sortOrder: sortOrder,
    );
  }

  static VaultCategoryModel fromEntity(VaultCategory entity) {
    final model = VaultCategoryModel()
      ..id = entity.id
      ..name = entity.name
      ..isDefault = entity.isDefault
      ..sortOrder = entity.sortOrder;
    return model;
  }
}

