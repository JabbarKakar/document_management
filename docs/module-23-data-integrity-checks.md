## Module 23 – Data Integrity Checks

### Objective

Detect and surface vault inconsistencies (DB rows vs encrypted files) early, and provide safe repair options.

### Scope

- Add integrity scan service:
  - Missing encrypted file for a DB document row.
  - Orphan encrypted file not referenced by DB.
  - Invalid metadata references (missing category ids).
- Trigger points:
  - Manual “Run integrity check” from Settings.
  - Optional startup health check (lightweight).
- Results UI with severity and repair actions.

### Key deliverables

- `VaultIntegrityService` with a typed report model.
- “Repair” actions:
  - Remove orphan files.
  - Mark broken documents / remove broken rows after user confirmation.
- Exportable report text for support/debug.

### Integration notes

- Keep repairs explicit; no destructive auto-fix without confirmation.
- Coordinate with Module 24 (Trash) if deletion semantics change.

### Out of scope

- Remote diagnostics or cloud repair.
