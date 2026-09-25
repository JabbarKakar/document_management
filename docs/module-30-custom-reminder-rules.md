## Module 30 – Custom Reminder Rules

### Objective

Allow document-specific reminder schedules beyond fixed global offsets.

### Scope

- Per-document reminder policy:
  - Default policy (from current app behavior).
  - Custom offsets/dates.
  - Disable reminders per document.
- UI in edit/details screens.

### Key deliverables

- Reminder policy model persisted with document.
- Scheduler integration with `ExpiryReminderService`.
- Validation for invalid dates/rules.

### Integration notes

- Preserve existing Module 8 behavior as default fallback.

### Out of scope

- Email/SMS reminder channels.
