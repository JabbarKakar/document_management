## Module 24 – Trash / Soft Delete

### Objective

Replace immediate hard-delete with a safer trash workflow and timed purge.

### Scope

- Soft delete moves documents to Trash state instead of permanent removal.
- Trash screen:
  - Restore document.
  - Permanently delete one/all.
- Auto-purge policy (e.g., 30 days configurable later).

### Key deliverables

- Schema changes (`deletedAt` or `isDeleted`) and migration.
- Provider/repository updates to exclude trash from normal lists.
- Batch actions support with trash semantics.

### Integration notes

- Expiry reminders: cancel while in trash; restore should reschedule.
- Module 23 integrity checks should understand trash state.

### Out of scope

- Cross-device trash sync.
