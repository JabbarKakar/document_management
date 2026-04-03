## Module 11 – Advanced Filtering

### Objective

Extend vault browsing beyond **search text** and **single category** with richer filters so users can narrow the list quickly.

### Scope

- **File type** filter: All / Images / PDFs / Other.
- **Expiry** filter groups, for example:
  - Has expiry / No expiry
  - Expired
  - Expiring within 7 / 30 days (thresholds can match notification logic from Module 8).
- Filters compose with **search** and **category** (AND semantics).
- Clear-all / reset filters action.
- Optional: persist last filter chips state (lightweight).

### Key deliverables

- UI: second row of chips, filter **bottom sheet**, or dedicated “Filters” entry point.
- Provider/repository: filter implementation (in-memory on current query vs pushed-down to Isar – decide by volume).
- Visual parity with existing `FilterChip` patterns on the home screen.

### Integration notes

- Align “expiring soon” definition with `ExpiryReminderService` / list-card urgent styling to avoid inconsistent copy.

### Out of scope

- Saved filter presets named by the user (could be Module 11b later).
