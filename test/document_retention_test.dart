import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/features/documents/domain/document_history.dart';
import 'package:document_management/features/documents/domain/expiry_calendar.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';
import 'package:document_management/features/documents/domain/vault_document_filters.dart';

void main() {
  test('trash remains recoverable until the exact retention boundary', () {
    final deleted = DateTime.utc(2026, 9, 1, 12);
    expect(
      VaultRetention.shouldPurge(
        deleted,
        deleted
            .add(const Duration(days: 30))
            .subtract(const Duration(microseconds: 1)),
      ),
      isFalse,
    );
    expect(
      VaultRetention.shouldPurge(
        deleted,
        deleted.add(const Duration(days: 30)),
      ),
      isTrue,
    );
  });

  test('expiry counts calendar dates across month and year boundaries', () {
    expect(
      calendarDaysUntilExpiry(
        DateTime(2027, 1, 1),
        now: DateTime(2026, 12, 31, 23, 59),
      ),
      1,
    );
    expect(
      calendarDaysUntilExpiry(DateTime(2026, 3, 9), now: DateTime(2026, 3, 8)),
      1,
    );
    expect(
      calendarDaysUntilExpiry(
        DateTime(2026, 9, 24),
        now: DateTime(2026, 9, 25),
      ),
      -1,
    );
  });

  test(
    'within-N-days filters include their last day and exclude expired files',
    () {
      final now = DateTime.now();
      VaultDocument document(int days) => VaultDocument(
        id: 1,
        title: 'Example',
        filePath: 'file.pdf',
        fileType: VaultDocumentFileType.pdf,
        createdAt: now,
        expiryDate: DateTime(now.year, now.month, now.day + days),
      );
      bool matches(int days, VaultExpiryFilter filter) =>
          documentMatchesAdvancedFilters(
            document(days),
            fileTypeFilter: VaultFileTypeFilter.all,
            expiryFilter: filter,
          );
      expect(matches(7, VaultExpiryFilter.expiringWithin7), isTrue);
      expect(matches(8, VaultExpiryFilter.expiringWithin7), isFalse);
      expect(matches(30, VaultExpiryFilter.expiringWithin30), isTrue);
      expect(matches(-1, VaultExpiryFilter.expiringWithin30), isFalse);
    },
  );
}
