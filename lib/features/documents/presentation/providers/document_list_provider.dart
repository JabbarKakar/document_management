import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../../core/services/expiry_reminder_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/document_thumbnail_cache_service.dart';
import '../../data/services/document_file_picker.dart';
import '../../domain/document_sorting.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/document_history.dart';
import '../../domain/expiry_calendar.dart';
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
  String? _errorMessage;
  int _queryGeneration = 0;
  String? get errorMessage => _errorMessage;
  List<VaultDocument> _documents = [];
  List<VaultDocument> _allDocuments = [];
  bool _cacheLoaded = false;
  String _smartView = 'all';
  String? _tagFilter;
  String get smartView => _smartView;
  String? get tagFilter => _tagFilter;
  List<String> get availableTags =>
      _allDocuments.expand((d) => d.tags).toSet().toList()..sort();
  VaultDocument? documentById(int id) {
    for (final document in _allDocuments) {
      if (document.id == id) return document;
    }
    return null;
  }

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
      _currentQuery.isNotEmpty || hasStructuredFilters;

  /// Category / file-type / expiry only (excludes search). Used for filter badge.
  bool get hasStructuredFilters =>
      _currentCategoryFilter != null ||
      _fileTypeFilter != VaultFileTypeFilter.all ||
      _expiryFilter != VaultExpiryFilter.any ||
      _smartView != 'all' ||
      _tagFilter != null;

  /// Call once after construction (see [main.dart] provider `create`).
  Future<void> startup() async {
    final stored = await _secureStorage.readDocumentListSort();
    _sortMode = VaultDocumentSort.fromStorage(stored);
    try {
      await purgeExpiredTrash();
    } catch (_) {
      _errorMessage =
          'Trash cleanup could not finish. You can retry from Trash.';
    }
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

  Future<void> loadDocuments() => _runFilteredQuery();

  Future<void> setSearchQuery(String query) async {
    _currentQuery = query;
    await _runFilteredQuery(refresh: false);
  }

  Future<void> setCategoryFilter(int? categoryId) async {
    _currentCategoryFilter = categoryId;
    await _runFilteredQuery(refresh: false);
  }

  Future<void> setFileTypeFilter(VaultFileTypeFilter filter) async {
    if (filter == _fileTypeFilter) return;
    _fileTypeFilter = filter;
    await _runFilteredQuery(refresh: false);
  }

  Future<void> setExpiryFilter(VaultExpiryFilter filter) async {
    if (filter == _expiryFilter) return;
    _expiryFilter = filter;
    await _runFilteredQuery(refresh: false);
  }

  void _resetStructuredFilterFields() {
    _currentCategoryFilter = null;
    _fileTypeFilter = VaultFileTypeFilter.all;
    _expiryFilter = VaultExpiryFilter.any;
    _smartView = 'all';
    _tagFilter = null;
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

  Future<void> _runFilteredQuery({bool refresh = true}) async {
    final generation = ++_queryGeneration;
    _isLoading = true;
    notifyListeners();
    try {
      if (refresh || !_cacheLoaded) {
        final loaded = await _repository.getAllDocuments();
        if (generation != _queryGeneration) return;
        _allDocuments = loaded;
        _cacheLoaded = true;
      }
      final query = _currentQuery.trim().toLowerCase();
      final baseList = _allDocuments.where((d) {
        if (_currentCategoryFilter != null &&
            d.categoryId != _currentCategoryFilter) {
          return false;
        }
        if (_tagFilter != null && !d.tags.contains(_tagFilter)) return false;
        if (_smartView == 'favorites' && !d.isFavorite) return false;
        if (_smartView == 'uncategorized' && d.categoryId != null) return false;
        if (_smartView == 'recent' &&
            DateTime.now().difference(d.createdAt).inDays >= 7) {
          return false;
        }
        if (_smartView == 'expiring' &&
            (d.expiryDate == null ||
                calendarDaysUntilExpiry(d.expiryDate!) > 30)) {
          return false;
        }
        return query.isEmpty ||
            [
              d.title,
              d.notes ?? '',
              d.tags.join(' '),
              d.extractedText ?? '',
            ].any((text) => text.toLowerCase().contains(query));
      }).toList();
      if (generation != _queryGeneration) return;
      _documents = applyAdvancedFilters(
        baseList,
        fileTypeFilter: _fileTypeFilter,
        expiryFilter: _expiryFilter,
      );
      _applySortToCurrentList();

      _isLoading = false;
      notifyListeners();
    } catch (_) {
      if (generation == _queryGeneration) {
        _errorMessage = 'Could not load documents. Please retry.';
      }
    } finally {
      if (generation == _queryGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setSmartView(String value) async {
    _smartView = value;
    await _runFilteredQuery(refresh: false);
  }

  Future<void> setTagFilter(String? value) async {
    _tagFilter = value;
    await _runFilteredQuery(refresh: false);
  }

  Future<List<VaultDocument>> getTrash() => _repository.getTrash();

  Future<void> purgeExpiredTrash() async {
    final now = DateTime.now();
    for (final document in await _repository.getTrash()) {
      if (VaultRetention.shouldPurge(document.deletedAt!, now)) {
        await _repository.permanentlyDeleteDocument(document.id);
      }
    }
  }

  Future<void> restoreDocument(int id) async {
    final document = await _repository.restoreDocument(id);
    await _rescheduleSafely(document);
    await _runFilteredQuery();
  }

  Future<void> purgeDocument(int id) async {
    await _repository.permanentlyDeleteDocument(id);
    _thumbnailCache.removeByDocument(id);
    await _runFilteredQuery();
  }

  Future<void> restoreVersion(int id, String path) async {
    final document = await _repository.restoreVersion(id, path);
    _thumbnailCache.removeByDocument(id);
    await _rescheduleSafely(document);
    await _runFilteredQuery();
  }

  Future<void> updateOrganization(
    int id, {
    bool? favorite,
    List<String>? tags,
    List<int>? reminderOffsets,
    bool? remindersDisabled,
    String? extractedText,
    String? expectedFilePath,
  }) async {
    final document = await _repository.updateOrganization(
      id,
      favorite: favorite,
      tags: tags,
      reminderOffsets: reminderOffsets,
      remindersDisabled: remindersDisabled,
      extractedText: extractedText,
      expectedFilePath: expectedFilePath,
    );
    await _rescheduleSafely(document);
    await _runFilteredQuery();
  }

  Future<void> recordExport(int id) async =>
      _repository.recordActivity(id, 'Exported a decrypted copy');
  Future<void> recordEncryptedExport(int id) async =>
      _repository.recordActivity(id, 'Prepared a password-protected export');

  Future<void> addDocumentFromPicker({
    required String title,
    required PickedDocumentFile pickedFile,
    DateTime? expiryDate,
    String? notes,
    int? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final added = await _repository.addDocument(
        title: title,
        fileBytes: pickedFile.bytes,
        originalFileName: pickedFile.fileName,
        fileType: pickedFile.fileType,
        expiryDate: expiryDate,
        notes: notes,
        categoryId: categoryId,
      );
      await _rescheduleSafely(added);

      await _runFilteredQuery();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BulkImportReport> importDocumentsFromPickerFiles({
    required List<PickedDocumentFile> files,
    int? categoryId,
    bool Function()? isCancelled,
    void Function({
      required int completed,
      required int total,
      required String fileName,
    })?
    onProgress,
  }) async {
    if (files.isEmpty) {
      return BulkImportReport(total: 0, succeeded: 0, failedNames: const []);
    }

    _isLoading = true;
    notifyListeners();
    try {
      var completed = 0;
      var succeeded = 0;
      final failed = <String>[];
      final retryFiles = <PickedDocumentFile>[];

      for (final f in files) {
        if (isCancelled?.call() == true) {
          retryFiles.addAll(files.skip(completed));
          break;
        }
        try {
          final added = await _repository.addDocument(
            title: _defaultTitleFromFileName(f.fileName),
            fileBytes: f.bytes,
            originalFileName: f.fileName,
            fileType: f.fileType,
            categoryId: categoryId,
            expiryDate: null,
            notes: null,
          );
          await _rescheduleSafely(added);
          succeeded++;
        } catch (_) {
          failed.add(f.fileName);
          retryFiles.add(f);
        } finally {
          completed++;
          onProgress?.call(
            completed: completed,
            total: files.length,
            fileName: f.fileName,
          );
        }
      }

      await _runFilteredQuery();
      return BulkImportReport(
        total: files.length,
        succeeded: succeeded,
        failedNames: failed,
        retryFiles: retryFiles,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    await _rescheduleSafely(updated);
    await _runFilteredQuery();
  }

  /// Module 17: save metadata and optionally replace the encrypted file.
  Future<void> saveExistingDocumentChanges({
    required VaultDocument existing,
    required String title,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
    PickedDocumentFile? replacementFile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (replacementFile != null) {
        await _repository.replaceDocumentFile(
          id: existing.id,
          fileBytes: replacementFile.bytes,
          originalFileName: replacementFile.fileName,
          fileType: replacementFile.fileType,
        );
        _thumbnailCache.removeByDocument(existing.id);
        await _expiryReminders.deleteNotificationPreviewForDocument(
          existing.id,
        );
      }

      final updated = await _repository.updateDocumentMetadata(
        id: existing.id,
        title: title,
        categoryId: categoryId,
        expiryDate: expiryDate,
        notes: notes,
      );
      await _rescheduleSafely(updated);
      await _runFilteredQuery();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Batch action (Module 12): set category for currently selected documents.
  Future<void> setCategoryForDocuments(
    List<VaultDocument> documents, {
    required int? categoryId,
  }) async {
    if (documents.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Batch action (Module 12): delete many documents in one refresh cycle.
  Future<void> deleteDocuments(List<VaultDocument> documents) async {
    if (documents.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      for (final doc in documents) {
        await _expiryReminders.cancelForDocument(doc.id);
        await _expiryReminders.deleteNotificationPreviewForDocument(doc.id);
        await _repository.deleteDocument(doc);
        _thumbnailCache.removeByDocument(doc.id);
      }
      await _runFilteredQuery();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDocument(VaultDocument document) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _expiryReminders.cancelForDocument(document.id);
      await _expiryReminders.deleteNotificationPreviewForDocument(document.id);
      await _repository.deleteDocument(document);
      _thumbnailCache.removeByDocument(document.id);
      await _runFilteredQuery();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _rescheduleSafely(VaultDocument document) async {
    try {
      await _expiryReminders.rescheduleForDocument(document);
    } catch (_) {
      _errorMessage =
          'Document saved. Reminders could not be scheduled; retry from Settings.';
    }
  }

  String _defaultTitleFromFileName(String fileName) {
    final name = p.basenameWithoutExtension(fileName).trim();
    return name.isEmpty ? 'Imported document' : name;
  }
}

class BulkImportReport {
  BulkImportReport({
    required this.total,
    required this.succeeded,
    required this.failedNames,
    this.retryFiles = const [],
  });

  final int total;
  final int succeeded;
  final List<String> failedNames;
  final List<PickedDocumentFile> retryFiles;
}
