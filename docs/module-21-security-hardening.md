## Module 21 – Security Hardening

### Objective

Strengthen **access control** and **sensitive actions** beyond the current lock screen.

### Scope

- **Auto-lock**: configurable idle timeout (e.g. 1 / 5 / 15 min) when app goes to background or no user interaction (align with `AuthStateProvider` / lifecycle observer).
- **Biometric or PIN gate** for high-risk actions:
  - Export (Module 18), Backup (Module 20), optional **Reveal path** / developer toggles.
- Optional: **screenshots disabled** on sensitive screens (Android `FLAG_SECURE` – platform-specific, assess UX).
- Settings UI under security section (Module 9).

### Key deliverables

- Central helper: `await assertUnlockedOrPrompt(context, reason: …)` reusable from screens.
- Persistence: timeout and policy flags in secure storage.

### Integration notes

- Don’t deadlock: if already on lock screen, skip double prompt.
- Test background/foreground transitions on Android and iOS.

### Out of scope

- Remote wipe, MDM.
