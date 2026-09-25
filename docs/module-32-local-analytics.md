## Module 32 – Local Analytics

### Objective

Provide privacy-safe vault insights stored fully on-device.

### Scope

- Metrics:
  - Total docs
  - Storage usage estimate
  - Docs by type/category
  - Import/export trends
- Present in a dashboard panel under Settings/About.

### Key deliverables

- Aggregation service with cached snapshots.
- Lightweight charts/cards UI.
- No network transmission of analytics data.

### Integration notes

- Respect lock state; hide analytics on lock.

### Out of scope

- Remote telemetry.
