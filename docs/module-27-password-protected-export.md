## Module 27 – Password-Protected Export Package

### Objective

Offer secure export packages (encrypted archive) as an alternative to plaintext exports.

### Scope

- Export selected docs into one encrypted package file.
- User sets package password before export.
- Include metadata manifest (titles, dates) without plaintext content leaks.

### Key deliverables

- Archive + encryption pipeline service.
- Password strength guidance and confirmation UI.
- Import/decrypt flow can be future companion module.

### Integration notes

- Complements Module 18 plaintext export, not a replacement.
- Sensitive action guard from Module 21 should apply.

### Out of scope

- Public key cryptography / enterprise key mgmt.
