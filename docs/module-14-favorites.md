## Module 14 – Favorites (Pinned Documents)

### Objective

Let users **pin** important documents for faster access.

### Scope

- Schema: `isFavorite` (or `pinnedAt`) on document model / Isar.
- Toggle from list (star icon), details sheet, or viewer app bar.
- Home: optional **Favorites** filter chip or top section “Pinned”.
- Sort: optional “Favorites first” sub-sort (could combine with Module 10).

### Key deliverables

- Migration or default `false` for existing rows.
- Repository + provider methods: `setFavorite(id, bool)`.
- UI affordances consistent with Material icons (`star`, `star_border`).

### Integration notes

- Batch actions (Module 12): “Add to favorites / Remove from favorites”.

### Out of scope

- Cloud sync of favorites across devices.
