## Module 13 – Document Details Bottom Sheet

### Objective

Give a **read-only summary** of a document with quick actions without opening the full viewer or editor.

### Scope

- Trigger: overflow menu on list card, secondary tap, or an explicit “Info” icon (avoid conflicting with primary tap = viewer).
- Sheet content:
  - Title, category name, file type, created date, expiry, notes preview.
  - Actions: **Open**, **Edit**, **Delete**, **Share** (if Module 18/share exists – else stub).
- Dismiss-safe; uses existing theme (`ColorScheme`, typography).

### Key deliverables

- Reusable `DocumentDetailsSheet` widget.
- Resolves **category id → name** via `CategoryListProvider` or repository.
- Strings / accessibility labels for screen readers.

### Integration notes

- Keep encrypted **file path** and raw paths out of user-visible strings unless explicitly “technical details” mode.

### Out of scope

- Inline editing inside the sheet (use existing edit screen).
