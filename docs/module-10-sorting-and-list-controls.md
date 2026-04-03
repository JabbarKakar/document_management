## Module 10 – Sorting & List Controls

### Objective

Let users change **how documents are ordered** in the vault list without changing which documents are shown (beyond current search/category filters).

### Scope

- Sort modes, for example:
  - **Newest first** (default – matches typical `createdAt` desc).
  - **Oldest first**
  - **Title A → Z** / **Z → A** (case-insensitive).
  - **Expiry soonest** (documents with no expiry last, or grouped separately).
- Persist last chosen sort in **secure storage** or a small settings model (align with Module 9 patterns).
- UI: sort **menu** or **bottom sheet** from the home app bar (or overflow), consistent with existing Material styling.

### Key deliverables

- `DocumentListProvider` (or repository): apply sort after filter query.
- Settings key or user preference for default sort.
- Widget tests or manual QA checklist for each sort mode with mixed data.

### Integration notes

- Compose with existing `setSearchQuery` / `setCategoryFilter` – sort applies to the **current result set**.
- Document sort field requirements in `VaultDocument` / Isar queries (may need composite indexes for performance).

### Out of scope (later modules)

- Custom user-defined sort orders, multi-column sort.
