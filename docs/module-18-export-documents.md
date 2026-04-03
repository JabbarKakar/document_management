## Module 18 – Export Documents

### Objective

Let users **export decrypted copies** of selected documents to user-chosen locations (Downloads, Files app) or share sheet.

### Scope

- Export **one or many** (pairs with Module 12).
- Preserve sensible file names from title + original extension; sanitize characters.
- Optional: export as **ZIP** for multi-select.
- Confirm UX: “Files will be saved **unencrypted** outside the vault.”
- Re-auth (Module 21) optional hook before export.

### Key deliverables

- Use `share_plus` / platform file APIs as appropriate; Android `MediaStore` or scoped storage compliance.
- Progress for multi-export; cancel support if straightforward.

### Integration notes

- Temp files: write to cache, share, delete (pattern similar to `DocumentViewerScreen` share).

### Out of scope

- Encrypted export format for third-party tools (could be future module).
