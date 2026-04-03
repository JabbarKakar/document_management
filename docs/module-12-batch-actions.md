## Module 12 – Batch Actions

### Objective

Allow **multi-select** in the document list so users can act on many documents at once.

### Scope

- Enter **selection mode** (long-press or toolbar “Select”).
- Checkbox or selection affordance on each row; **Select all** / **Clear selection** for current list.
- Actions (minimum viable):
  - **Delete** selected (with confirmation).
  - **Set category** for selected (including clear category).
- Optional second wave: **Clear expiry** for selected, **Export** selected (ties to Module 18).

### Key deliverables

- `DocumentsHomeScreen` (or extracted list widget): selection state locally or via small `SelectionController` / notifier.
- Batch delete via repository or loop with **notification reschedule** / cancellation per doc (Module 8 parity).
- Loading / error handling; don’t leave half-updated notification state.

### Integration notes

- Thumbnails and navigation: tapping a row in selection mode toggles selection; separate **Preview** action optional.
- Respect filters: “Select all” = all **visible** items only.

### Out of scope

- Cross-folder batch move (no folders yet).
