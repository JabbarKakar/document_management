import 'package:flutter/foundation.dart';

import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/services/document_file_picker.dart';
import '../../domain/document_sorting.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/vault_document_sort.dart';

class DocumentListProvider extends ChangeNotifier {
  DocumentListProvider(
    this._repository,
    this._expiryReminders,
    this._secureStorage,
  );

  final DocumentRepository _repository;
  final ExpiryReminderService _expiryReminders;
  final SecureStorageService _secureStorage;

  bool _isLoading = false;
  List<VaultDocument> _documents = [];
  String _currentQuery = '';
  int? _currentCategoryFilter;
  VaultDocumentSort _sortMode = VaultDocumentSort.newestFirst;

  bool get isLoading => _isLoading;
  List<VaultDocument> get documents => _documents;
  String get searchQuery => _currentQuery;
  int? get categoryFilter => _currentCategoryFilter;
  VaultDocumentSort get sortMode => _sortMode;

  /// Call once after construction (see [main.dart] provider `create`).
  Future<void> startup() async {
    final stored = await _secureStorage.readDocumentListSort();
    _sortMode = VaultDocumentSort.fromStorage(stored);
    await loadDocuments();
  }

  Future<void> setSortMode(VaultDocumentSort mode) async {
    if (mode == _sortMode) return;
    _sortMode = mode;
    await _secureStorage.writeDocumentListSort(mode.storageValue);
    sortVaultDocuments(_documents, _sortMode);
    notifyListeners();
  }

  void _applySortToCurrentList() {
    sortVaultDocuments(_documents, _sortMode);
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    _documents = await _repository.getAllDocuments();
    _applySortToCurrentList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _currentQuery = query;
    await _runFilteredQuery();
  }

  Future<void> setCategoryFilter(int? categoryId) async {
    _currentCategoryFilter = categoryId;
    await _runFilteredQuery();
  }

  Future<void> _runFilteredQuery() async {
    _isLoading = true;
    notifyListeners();

    if (_currentQuery.isEmpty && _currentCategoryFilter == null) {
      _documents = await _repository.getAllDocuments();
    } else {
      _documents = await _repository.searchDocuments(
        query: _currentQuery,
        categoryId: _currentCategoryFilter,
      );
    }
    _applySortToCurrentList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDocumentFromPicker({
    required String title,
    required PickedDocumentFile pickedFile,
    DateTime? expiryDate,
    String? notes,
    int? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final added = await _repository.addDocument(
      title: title,
      fileBytes: pickedFile.bytes,
      originalFileName: pickedFile.fileName,
      fileType: pickedFile.fileType,
      expiryDate: expiryDate,
      notes: notes,
      categoryId: categoryId,
    );
    await _expiryReminders.rescheduleForDocument(added);

    await _runFilteredQuery();
  }

  Future<void> updateDocumentMetadata({
    required int id,
    required String title,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final updated = await _repository.updateDocumentMetadata(
      id: id,
      title: title,
      categoryId: categoryId,
      expiryDate: expiryDate,
      notes: notes,
    );
    await _expiryReminders.rescheduleForDocument(updated);
    await _runFilteredQuery();
  }

  Future<void> deleteDocument(VaultDocument document) async {
    _isLoading = true;
    notifyListeners();

    await _expiryReminders.cancelForDocument(document.id);
    await _expiryReminders.deleteNotificationPreviewForDocument(document.id);
    await _repository.deleteDocument(document);
    await _runFilteredQuery();
  }
}
