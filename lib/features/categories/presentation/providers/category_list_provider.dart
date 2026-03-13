import 'package:flutter/foundation.dart';

import '../../domain/entities/vault_category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryListProvider extends ChangeNotifier {
  CategoryListProvider(this._repository);

  final CategoryRepository _repository;

  bool _isLoading = false;
  List<VaultCategory> _categories = [];

  bool get isLoading => _isLoading;
  List<VaultCategory> get categories => _categories;

  Future<void> loadAndEnsureDefaults() async {
    _isLoading = true;
    notifyListeners();

    await _repository.ensureDefaultCategories();
    _categories = await _repository.getAllCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createCategory(String name) async {
    await _repository.createCategory(name);
    _categories = await _repository.getAllCategories();
    notifyListeners();
  }

  Future<void> renameCategory(
    VaultCategory category,
    String newName,
  ) async {
    await _repository.renameCategory(category, newName);
    _categories = await _repository.getAllCategories();
    notifyListeners();
  }

  Future<bool> deleteCategory(VaultCategory category) async {
    final ok = await _repository.deleteCategory(category);
    if (ok) {
      _categories = await _repository.getAllCategories();
      notifyListeners();
    }
    return ok;
  }
}

