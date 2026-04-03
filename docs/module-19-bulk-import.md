## Module 19 – Bulk Import

### Objective

Import **many files at once** into the vault with encryption and metadata defaults.

### Scope

- Entry: “Import folder” or multi-pick from file picker (platform limits apply).
- For each file: detect type (image/PDF/other), encrypt, insert row with **default title** (filename minus extension) and optional **single category** for the whole batch.
- Progress UI: count, current file, cancel (finish current optional).
- Summary: succeeded / failed paths.

### Key deliverables

- Background-friendly: consider `compute` or queued import to avoid ANR on huge batches.
- Notification scheduling per document (Module 8) batched or throttled.

### Integration notes

- Module 15: queue OCR after import or run lazy on first search – decide for UX.

### Out of scope

- Import from cloud drives inside the app (use OS picker only).
