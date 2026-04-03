import 'package:flutter/foundation.dart';

import '../../../../core/services/expiry_reminder_service.dart';
import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentListProvider extends ChangeNotifier {
  DocumentListProvider(
    this._repository,
    this._expiryReminders,
  );

  final DocumentRepository _repository;
  final ExpiryReminderService _expiryReminders;

  bool _isLoading = false;
  List<VaultDocument> _documents = [];
  String _currentQuery = '';
  int? _currentCategoryFilter;

  bool get isLoading => _isLoading;
  List<VaultDocument> get documents => _documents;
  String get searchQuery => _currentQuery;
  int? get categoryFilter => _currentCategoryFilter;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    _documents = await _repository.getAllDocuments();
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

    _documents = await _repository.getAllDocuments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDocument(VaultDocument document) async {
    _isLoading = true;
    notifyListeners();

    await _expiryReminders.cancelForDocument(document.id);
    await _expiryReminders.deleteNotificationPreviewForDocument(document.id);
    await _repository.deleteDocument(document);
    _documents = await _repository.getAllDocuments();

    _isLoading = false;
    notifyListeners();
  }
}

