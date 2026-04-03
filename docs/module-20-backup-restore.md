## Module 20 – Backup & Restore

### Objective

Provide a **full vault backup** (Isar DB + encrypted files + essential secure-storage flags **documented**, not necessarily duplicated) and a **controlled restore** path.

### Scope

- **Backup**: user picks output directory or share backup archive; package:
  - Isar database file(s)
  - `vault_documents` (or configured) tree
  - **README** in backup listing what must be restored together and that the **encryption key** in secure storage must match – or export key in backup (higher risk – make explicit).
- **Restore**: destructive confirmation; replace DB + files; restart app or re-init Isar.
- Integrity: optional checksum manifest.

### Key deliverables

- `BackupService` / `RestoreService` in `core/` with clear error types.
- Settings entries: **Create backup**, **Restore from backup** (with warnings).

### Integration notes

- Android/iOS storage permissions and scoped storage rules.
- After restore: `ExpiryReminderService.syncAll()` equivalent.

### Out of scope

- Incremental/cloud backups, multi-device sync.
