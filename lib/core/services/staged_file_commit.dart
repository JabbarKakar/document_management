/// Files cannot participate in the database transaction. Only an uncommitted
/// file is rolled back. Cleanup failures leave an orphan, never a broken row.
Future<T> commitStagedFile<T>({
  required Future<T> Function() commit,
  required Future<void> Function() rollbackFile,
  Future<void> Function()? cleanupSuperseded,
}) async {
  late final T result;
  try {
    result = await commit();
  } catch (_) {
    try {
      await rollbackFile();
    } catch (_) {
      /* Preserve original failure. */
    }
    rethrow;
  }
  try {
    await cleanupSuperseded?.call();
  } catch (_) {
    // Retain the committed file even if cleanup must be retried separately.
  }
  return result;
}
