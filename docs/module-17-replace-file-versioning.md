## Module 17 – Replace File & Optional Versioning

### Objective

Allow users to **update the encrypted file** for an existing document (new scan/PDF) while keeping metadata row and id stable.

### Scope

- **Minimum:** “Replace file” on edit screen: pick new file → encrypt to new storage name → update `filePath` (+ `fileType`) → delete old encrypted blob → reschedule notifications (Module 8) → invalidate thumbnails (Module 16).
- **Optional stretch:** **Version history** – keep prior blobs under a size cap or count (e.g. last 3); UI to restore.

### Key deliverables

- Repository method: `replaceDocumentFile(id, bytes, fileName, fileType)` transactional where possible.
- Rollback strategy if write fails mid-flight (orphan file cleanup).
- Edit screen UX: progress, error snackbars.

### Integration notes

- OCR index (Module 15) should re-run after replace.
- Notification preview files: delete old preview for doc id before scheduling new.

### Out of scope

- Diffing binary content; collaborative editing.
