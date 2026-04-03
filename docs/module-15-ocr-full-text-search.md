## Module 15 – OCR & Full-Text Search

### Objective

Improve **search** by indexing text extracted from **images** and **PDFs** stored in the vault (offline-first).

### Scope

- Choose stack: on-device OCR package(s) compatible with your targets (Android/iOS); handle permission and binary size tradeoffs.
- Persist **searchable text** (and optional language) per document – new Isar field(s) or sidecar collection.
- Pipeline:
  - On document add (and optionally on Module 17 replace-file): decrypt → extract text → store.
  - Background or progress UI for large PDFs.
- Extend search to match **title, notes, and extracted text** (with clear UX: maybe show “matched in document” snippet later).

### Key deliverables

- Extractor service interface + implementation(s).
- Re-index job for existing documents (Settings: “Rebuild search index”).
- Failure modes: OCR unavailable, timeout, encrypted/corrupt file – fall back to title/notes only.

### Integration notes

- Memory: stream or page PDF text extraction; don’t load entire mult‑hundred‑MB PDF into RAM unnecessarily.
- Privacy: all processing stays **on device**; document in module doc for users.

### Out of scope

- Handwriting recognition quality guarantees; cloud OCR.
