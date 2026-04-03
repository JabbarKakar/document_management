/// User-selected ordering for the vault document list (Module 10).
enum VaultDocumentSort {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA,
  expirySoonest;

  String get storageValue => switch (this) {
        newestFirst => 'newest',
        oldestFirst => 'oldest',
        titleAZ => 'title_az',
        titleZA => 'title_za',
        expirySoonest => 'expiry_soonest',
      };

  /// Short label for menus (English; extract later if you add l10n).
  String get menuLabel => switch (this) {
        newestFirst => 'Newest first',
        oldestFirst => 'Oldest first',
        titleAZ => 'Title A–Z',
        titleZA => 'Title Z–A',
        expirySoonest => 'Expiry soonest',
      };

  static VaultDocumentSort fromStorage(String? raw) {
    return switch (raw) {
      'oldest' => oldestFirst,
      'title_az' => titleAZ,
      'title_za' => titleZA,
      'expiry_soonest' => expirySoonest,
      _ => newestFirst,
    };
  }
}
