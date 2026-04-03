import 'entities/vault_document.dart';
import 'vault_document_sort.dart';

/// Sorts [documents] in place according to [sort].
void sortVaultDocuments(List<VaultDocument> documents, VaultDocumentSort sort) {
  switch (sort) {
    case VaultDocumentSort.newestFirst:
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case VaultDocumentSort.oldestFirst:
      documents.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case VaultDocumentSort.titleAZ:
      documents.sort(_titleThenNewest);
    case VaultDocumentSort.titleZA:
      documents.sort((a, b) => _titleThenNewest(b, a));
    case VaultDocumentSort.expirySoonest:
      documents.sort((a, b) {
        final ae = a.expiryDate;
        final be = b.expiryDate;
        if (ae == null && be == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (ae == null) return 1;
        if (be == null) return -1;
        final byExpiry = ae.compareTo(be);
        if (byExpiry != 0) return byExpiry;
        return b.createdAt.compareTo(a.createdAt);
      });
  }
}

int _titleThenNewest(VaultDocument a, VaultDocument b) {
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byTitle != 0) return byTitle;
  return b.createdAt.compareTo(a.createdAt);
}
