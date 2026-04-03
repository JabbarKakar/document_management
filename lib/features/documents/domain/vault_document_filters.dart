import 'entities/vault_document.dart';
import 'expiry_calendar.dart';

/// File-type facet (Module 11). PDF includes `.pdf` extension like the viewer/thumbnail.
enum VaultFileTypeFilter {
  all,
  image,
  pdf,
  other;

  String get chipLabel => switch (this) {
        all => 'All',
        image => 'Images',
        pdf => 'PDFs',
        other => 'Other',
      };
}

/// Mutually exclusive expiry facet. [any] means no expiry-based filtering.
enum VaultExpiryFilter {
  any,
  hasExpiry,
  noExpiry,
  expired,
  expiringWithin7,
  expiringWithin30;

  String get chipLabel => switch (this) {
        any => 'Any expiry',
        hasExpiry => 'Has expiry date',
        noExpiry => 'No expiry date',
        expired => 'Expired',
        expiringWithin7 => 'Within 7 days',
        expiringWithin30 => 'Within 30 days',
      };
}

bool _isPdfLike(VaultDocument d) {
  return d.fileType == VaultDocumentFileType.pdf ||
      d.filePath.toLowerCase().endsWith('.pdf');
}

bool _matchesFileType(VaultDocument d, VaultFileTypeFilter filter) {
  return switch (filter) {
    VaultFileTypeFilter.all => true,
    VaultFileTypeFilter.image => d.fileType == VaultDocumentFileType.image,
    VaultFileTypeFilter.pdf => _isPdfLike(d),
    VaultFileTypeFilter.other =>
      d.fileType == VaultDocumentFileType.other && !_isPdfLike(d),
  };
}

bool _matchesExpiry(VaultDocument d, VaultExpiryFilter filter) {
  return switch (filter) {
    VaultExpiryFilter.any => true,
    VaultExpiryFilter.hasExpiry => d.expiryDate != null,
    VaultExpiryFilter.noExpiry => d.expiryDate == null,
    VaultExpiryFilter.expired =>
      d.expiryDate != null && calendarDaysUntilExpiry(d.expiryDate!) < 0,
    VaultExpiryFilter.expiringWithin7 =>
      d.expiryDate != null &&
          _notExpired(d.expiryDate!) &&
          calendarDaysUntilExpiry(d.expiryDate!) < 7,
    VaultExpiryFilter.expiringWithin30 =>
      d.expiryDate != null &&
          _notExpired(d.expiryDate!) &&
          calendarDaysUntilExpiry(d.expiryDate!) < 30,
  };
}

bool _notExpired(DateTime expiry) => calendarDaysUntilExpiry(expiry) >= 0;

/// AND of file-type and expiry facets.
bool documentMatchesAdvancedFilters(
  VaultDocument d, {
  required VaultFileTypeFilter fileTypeFilter,
  required VaultExpiryFilter expiryFilter,
}) {
  if (!_matchesFileType(d, fileTypeFilter)) return false;
  if (!_matchesExpiry(d, expiryFilter)) return false;
  return true;
}

List<VaultDocument> applyAdvancedFilters(
  List<VaultDocument> source, {
  required VaultFileTypeFilter fileTypeFilter,
  required VaultExpiryFilter expiryFilter,
}) {
  return source
      .where(
        (d) => documentMatchesAdvancedFilters(
          d,
          fileTypeFilter: fileTypeFilter,
          expiryFilter: expiryFilter,
        ),
      )
      .toList();
}
