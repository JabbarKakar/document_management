import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/core/services/staged_file_commit.dart';
import 'package:document_management/core/services/document_thumbnail_cache_service.dart';

void main() {
  test(
    'post-commit cleanup failure never removes the live replacement',
    () async {
      var rolledBack = false;
      final result = await commitStagedFile(
        commit: () async => 'new-live-path',
        rollbackFile: () async {
          rolledBack = true;
        },
        cleanupSuperseded: () async => throw StateError('disk failure'),
      );
      expect(result, 'new-live-path');
      expect(rolledBack, isFalse);
    },
  );
  test('failed database commit rolls back only the staged file', () async {
    var rolledBack = false;
    var cleanedOld = false;
    await expectLater(
      commitStagedFile<void>(
        commit: () async => throw StateError('database failure'),
        rollbackFile: () async {
          rolledBack = true;
        },
        cleanupSuperseded: () async {
          cleanedOld = true;
        },
      ),
      throwsStateError,
    );
    expect(rolledBack, isTrue);
    expect(cleanedOld, isFalse);
  });
  test('late thumbnails cannot repopulate cache after lock', () async {
    final cache = DocumentThumbnailCacheService();
    final pending = Completer<Uint8List?>();
    final load = cache.getOrLoad(
      key: '1|document',
      loader: () => pending.future,
    );
    cache.clear();
    pending.complete(Uint8List.fromList([1, 2, 3]));
    expect(await load, isNull);
    expect(cache.entryCount, 0);
  });
}
