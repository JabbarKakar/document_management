import 'dart:collection';
import 'dart:typed_data';

/// In-memory LRU cache for list thumbnails (Module 16).
///
/// Keys should include enough info to invalidate naturally when a document file
/// changes, for example: `<documentId>|<filePath>`.
class DocumentThumbnailCacheService {
  DocumentThumbnailCacheService({
    this.maxEntries = 120,
    this.maxBytes = 18 * 1024 * 1024,
  });

  final int maxEntries;
  final int maxBytes;

  final LinkedHashMap<String, Uint8List> _entries = LinkedHashMap();
  final Map<String, Future<Uint8List?>> _inFlight = {};
  int _bytesUsed = 0;

  int get bytesUsed => _bytesUsed;
  int get entryCount => _entries.length;

  Uint8List? get(String key) {
    final hit = _entries.remove(key);
    if (hit == null) return null;
    // Touch for LRU behavior.
    _entries[key] = hit;
    return hit;
  }

  Future<Uint8List?> getOrLoad({
    required String key,
    required Future<Uint8List?> Function() loader,
  }) {
    final hit = get(key);
    if (hit != null) return Future<Uint8List?>.value(hit);

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final task = () async {
      try {
        final loaded = await loader();
        if (loaded == null || loaded.isEmpty) return null;
        _put(key, loaded);
        return loaded;
      } finally {
        _inFlight.remove(key);
      }
    }();

    _inFlight[key] = task;
    return task;
  }

  void removeByDocument(int documentId) {
    final prefix = '$documentId|';
    final keys = _entries.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      final removed = _entries.remove(key);
      if (removed != null) {
        _bytesUsed -= removed.lengthInBytes;
      }
    }
    final pendingKeys = _inFlight.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in pendingKeys) {
      _inFlight.remove(key);
    }
  }

  void clear() {
    _entries.clear();
    _inFlight.clear();
    _bytesUsed = 0;
  }

  void _put(String key, Uint8List value) {
    final existing = _entries.remove(key);
    if (existing != null) {
      _bytesUsed -= existing.lengthInBytes;
    }
    _entries[key] = value;
    _bytesUsed += value.lengthInBytes;
    _evictIfNeeded();
  }

  void _evictIfNeeded() {
    while (_entries.length > maxEntries || _bytesUsed > maxBytes) {
      final oldestKey = _entries.keys.first;
      final removed = _entries.remove(oldestKey);
      if (removed != null) {
        _bytesUsed -= removed.lengthInBytes;
      }
    }
  }
}
