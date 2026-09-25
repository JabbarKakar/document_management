## Module 28 – Audit Timeline

### Objective

Track major document events for accountability and troubleshooting.

### Scope

- Event types: created, edited metadata, replaced file, exported, deleted/restored.
- Per-document timeline view.
- Optional global recent activity feed.

### Key deliverables

- Audit event model + storage.
- Helper methods to write events from providers/services.
- Read UI in details sheet or dedicated screen.

### Integration notes

- Keep payload privacy-safe (no decrypted content).

### Out of scope

- Tamper-proof forensic logging.
