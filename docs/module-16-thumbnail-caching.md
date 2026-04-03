## Module 16 – Thumbnail Caching

### Objective

Reduce repeated **decrypt + decode** work when scrolling the document list by caching **preview bytes** or **decoded textures** responsibly.

### Scope

- In-memory LRU cache (key: `documentId` + `filePath` mtime or `updatedAt` if added).
- Optional: small on-disk cache of **JPEG thumbnails** under app support dir (encrypted-at-rest optional – decide threat model).
- Invalidate cache on: document delete, replace file (Module 17), encryption key rotation (if ever).
- Tune max cache size / entry count; evict on low memory if feasible.

### Key deliverables

- `ThumbnailCache` service (or mixin) used by `VaultDocumentThumbnail`.
- Unit-level tests for eviction / invalidation rules where pure Dart allows.

### Integration notes

- Current list uses live decrypt; Module 16 should **not** change UX except performance and battery.
- PDF render lock (Android) – cache reduces how often the lock is hit.

### Out of scope

- Server-side thumbnail generation.
