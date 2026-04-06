import 'package:flutter/foundation.dart';

import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/document_thumbnail_cache_service.dart';
import '../../data/services/document_file_picker.dart';
import '../../domain/document_sorting.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/vault_document_filters.dart';
import '../../domain/vault_document_sort.dart';

class DocumentListProvider extends ChangeNotifier {
  DocumentListProvider(
    this._repository,
    this._expiryReminders,
    this._secureStorage,
    this._thumbnailCache,
  );

  final DocumentRepository _repository;
  final ExpiryReminderService _expiryReminders;
  final SecureStorageService _secureStorage;
  final DocumentThumbnailCacheService _thumbnailCache;

  bool _isLoading = false;
  List<VaultDocument> _documents = [];
  String _currentQuery = '';
  int? _currentCategoryFilter;
  VaultDocumentSort _sortMode = VaultDocumentSort.newestFirst;
  VaultFileTypeFilter _fileTypeFilter = VaultFileTypeFilter.all;
  VaultExpiryFilter _expiryFilter = VaultExpiryFilter.any;

  bool get isLoading => _isLoading;
  List<VaultDocument> get documents => _documents;
  String get searchQuery => _currentQuery;
  int? get categoryFilter => _currentCategoryFilter;
  VaultDocumentSort get sortMode => _sortMode;
  VaultFileTypeFilter get fileTypeFilter => _fileTypeFilter;
  VaultExpiryFilter get expiryFilter => _expiryFilter;

  /// Search, category, file type, or expiry filters (sort is not included).
  bool get hasActiveListFilters =>
      _currentQuery.isNotEmpty ||
      hasStructuredFilters;

  /// Category / file-type / expiry only (excludes search). Used for filter badge.
  bool get hasStructuredFilters =>
      _currentCategoryFilter != null ||
      _fileTypeFilter != VaultFileTypeFilter.all ||
      _expiryFilter != VaultExpiryFilter.any;

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

    final baseList = await _repository.getAllDocuments();
    _documents = applyAdvancedFilters(
      baseList,
      fileTypeFilter: _fileTypeFilter,
      expiryFilter: _expiryFilter,
    );
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

  Future<void> setFileTypeFilter(VaultFileTypeFilter filter) async {
    if (filter == _fileTypeFilter) return;
    _fileTypeFilter = filter;
    await _runFilteredQuery();
  }

  Future<void> setExpiryFilter(VaultExpiryFilter filter) async {
    if (filter == _expiryFilter) return;
    _expiryFilter = filter;
    await _runFilteredQuery();
  }

  void _resetStructuredFilterFields() {
    _currentCategoryFilter = null;
    _fileTypeFilter = VaultFileTypeFilter.all;
    _expiryFilter = VaultExpiryFilter.any;
  }

  /// Resets category, file type, and expiry. Leaves the search query as-is.
  Future<void> clearStructuredFilters() async {
    _resetStructuredFilterFields();
    await _runFilteredQuery();
  }

  /// Clears search, category, file-type, and expiry filters (not sort).
  Future<void> clearAllListFilters() async {
    _currentQuery = '';
    _resetStructuredFilterFields();
    await _runFilteredQuery();
  }

  Future<void> _runFilteredQuery() async {
    _isLoading = true;
    notifyListeners();

    final List<VaultDocument> baseList;
    if (_currentQuery.isEmpty && _currentCategoryFilter == null) {
      baseList = await _repository.getAllDocuments();
    } else {
      baseList = await _repository.searchDocuments(
        query: _currentQuery,
        categoryId: _currentCategoryFilter,
      );
    }
    _documents = applyAdvancedFilters(
      baseList,
      fileTypeFilter: _fileTypeFilter,
      expiryFilter: _expiryFilter,
    );
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

  /// Batch action (Module 12): set category for currently selected documents.
  Future<void> setCategoryForDocuments(
    List<VaultDocument> documents, {
    required int? categoryId,
  }) async {
    if (documents.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    for (final doc in documents) {
      await _repository.updateDocumentMetadata(
        id: doc.id,
        title: doc.title,
        categoryId: categoryId,
        expiryDate: doc.expiryDate,
        notes: doc.notes,
      );
    }
    await _runFilteredQuery();
  }

  /// Batch action (Module 12): delete many documents in one refresh cycle.
  Future<void> deleteDocuments(List<VaultDocument> documents) async {
    if (documents.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    for (final doc in documents) {
      await _expiryReminders.cancelForDocument(doc.id);
      await _expiryReminders.deleteNotificationPreviewForDocument(doc.id);
      await _repository.deleteDocument(doc);
      _thumbnailCache.removeByDocument(doc.id);
    }
    await _runFilteredQuery();
  }

  Future<void> deleteDocument(VaultDocument document) async {
    _isLoading = true;
    notifyListeners();

    await _expiryReminders.cancelForDocument(document.id);
    await _expiryReminders.deleteNotificationPreviewForDocument(document.id);
    await _repository.deleteDocument(document);
    _thumbnailCache.removeByDocument(document.id);
    await _runFilteredQuery();
  }
}
