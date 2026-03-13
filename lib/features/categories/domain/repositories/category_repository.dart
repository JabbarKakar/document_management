import '../../../documents/domain/entities/vault_document.dart';
import '../entities/vault_category.dart';

abstract class CategoryRepository {
  Future<List<VaultCategory>> getAllCategories();
  Future<void> ensureDefaultCategories();
  Future<VaultCategory> createCategory(String name);
  Future<VaultCategory> renameCategory(VaultCategory category, String newName);
  Future<bool> deleteCategory(VaultCategory category);

  Future<List<VaultDocument>> getDocumentsForCategory(int categoryId);
}

