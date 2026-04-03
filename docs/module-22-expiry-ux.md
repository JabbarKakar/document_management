## Module 22 – Expiry UX Enhancements

### Objective

Make **expiry visibility and maintenance** easier without changing core notification behavior (Module 8).

### Scope

- **Dedicated surfaces:**
  - Filter or tab: **Expiring soon** / **Expired** (overlaps Module 11 – merge docs when implementing).
  - Optional home **banner** or compact list: “N documents expiring this week.”
- **Quick actions** on a document:
  - **Extend expiry** by preset (+1 month, +3 months, +1 year) or custom date.
  - Optional: **Mark as renewed** (bump expiry without editing full sheet).
- Copy and icons consistent with list “urgent” red styling (< 7 days).

### Key deliverables

- Provider methods: `extendExpiry(documentId, DateTime newExpiry)` or delta-based.
- Reschedule notifications after change (reuse existing reschedule API).

### Integration notes

- Edit screen and list card should reflect new dates immediately after in-app updates.

### Out of scope

- Email/SMS reminders (offline vault).
