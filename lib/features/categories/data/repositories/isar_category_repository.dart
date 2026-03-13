import 'package:isar/isar.dart';

import '../../../documents/data/models/vault_document_model.dart';
import '../../../documents/domain/entities/vault_document.dart';
import '../../domain/entities/vault_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/vault_category_model.dart';

class IsarCategoryRepository implements CategoryRepository {
  IsarCategoryRepository(this._isar);

  final Isar _isar;

  IsarCollection<VaultCategoryModel> get _categories =>
      _isar.collection<VaultCategoryModel>();

  IsarCollection<VaultDocumentModel> get _documents =>
      _isar.collection<VaultDocumentModel>();

  static const List<String> _defaultNames = <String>[
    'Identity',
    'Education',
    'Travel',
    'Medical',
    'Finance',
    'Insurance',
    'Other',
  ];

  @override
  Future<List<VaultCategory>> getAllCategories() async {
    final models =
        await _categories.where().sortBySortOrder().thenByName().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> ensureDefaultCategories() async {
    final existingCount = await _categories.count();
    if (existingCount > 0) {
      return;
    }

    await _isar.writeTxn(() async {
      for (var i = 0; i < _defaultNames.length; i++) {
        final model = VaultCategoryModel()
          ..name = _defaultNames[i]
          ..isDefault = true
          ..sortOrder = i;
        await _categories.put(model);
      }
    });
  }

  @override
  Future<VaultCategory> createCategory(String name) async {
    final maxSort =
        await _categories.where().sortBySortOrderDesc().findFirst();
    final nextSort = (maxSort?.sortOrder ?? (_defaultNames.length - 1)) + 1;

    final model = VaultCategoryModel()
      ..name = name
      ..isDefault = false
      ..sortOrder = nextSort;

    final id = await _isar.writeTxn<int>(() async {
      return await _categories.put(model);
    });
    model.id = id;
    return model.toEntity();
  }

  @override
  Future<VaultCategory> renameCategory(
    VaultCategory category,
    String newName,
  ) async {
    final existing = await _categories.get(category.id);
    if (existing == null) {
      throw StateError('Category not found');
    }
    existing.name = newName;
    await _isar.writeTxn(() => _categories.put(existing));
    return existing.toEntity();
  }

  @override
  Future<bool> deleteCategory(VaultCategory category) async {
    final inUse = await _documents
            .filter()
            .categoryIdEqualTo(category.id)
            .limit(1)
            .findFirst() !=
        null;
    if (inUse) {
      return false;
    }

    final deleted =
        await _isar.writeTxn<bool>(() => _categories.delete(category.id));
    return deleted;
  }

  @override
  Future<List<VaultDocument>> getDocumentsForCategory(int categoryId) async {
    final models = await _documents
        .filter()
        .categoryIdEqualTo(categoryId)
        .sortByCreatedAtDesc()
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }
}

