import 'package:flutter/foundation.dart';

import '../../data/services/document_file_picker.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentListProvider extends ChangeNotifier {
  DocumentListProvider(this._repository);

  final DocumentRepository _repository;

  bool _isLoading = false;
  List<VaultDocument> _documents = [];
  String _currentQuery = '';
  int? _currentCategoryFilter;

  bool get isLoading => _isLoading;
  List<VaultDocument> get documents => _documents;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    _documents = await _repository.getAllDocuments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> applySearch({
    String? query,
    int? categoryId,
  }) async {
    _currentQuery = query ?? '';
    _currentCategoryFilter = categoryId;

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

    await _repository.addDocument(
      title: title,
      fileBytes: pickedFile.bytes,
      originalFileName: pickedFile.fileName,
      fileType: pickedFile.fileType,
      expiryDate: expiryDate,
      notes: notes,
      categoryId: categoryId,
    );

    _documents = await _repository.getAllDocuments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDocument(VaultDocument document) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteDocument(document);
    _documents = await _repository.getAllDocuments();

    _isLoading = false;
    notifyListeners();
  }
}

