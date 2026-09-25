# Security and recovery implementation — first delivery

Product decisions: personal/offline; Android and iOS; device credentials may
unlock independently of the vault PIN. No server, cloud account, or remote reset.

## Delivered

- A nested protected navigator inside `VaultSessionGate`; all app dialogs and
  the date picker use that navigator. Lock removes sensitive routes from painting,
  hit testing, focus and semantics while preserving draft state.
- Real idle timer and execution-time checks for file reads/writes and document
  mutations; lock clears the key and thumbnail caches. Late cache work is rejected.
- One new-PIN policy, legacy access, salted slow PIN verifiers, persisted cooldown,
  device unlock, and fresh-device-authenticated forgotten-PIN reset.
- Android FragmentActivity/AppCompat host and iOS picker usage descriptions.
- Portable password-encrypted logical backups with preflight validation and
  all-or-nothing database restore into an empty vault. Paths and device keys are
  never taken from an archive. A failed restore cleans only newly staged files.
- Replacement cleanup cannot delete a committed replacement. File names are
  random and file operations reject paths outside the vault. Missing encryption
  keys never silently create a replacement key over an existing vault.
- Private notification titles by default, no plaintext notification images, and
  cleanup of legacy artwork. A settings toggle allows titles without images.
- Confirmation for single deletion, shared export behavior, bounded temporary
  export lifetime, in-memory PDF viewing, and recoverable save errors.

## Automated validation

Run `flutter analyze` and `flutter test`. Regression tests cover the protected
navigation stack including dialogs, idle lock, cancelled device auth, PIN reset,
persisted cooldown, PIN migration, backup encryption/metadata round-trip, wrong
password and ciphertext tampering, malformed archive paths/references, storage
containment, and commit/cleanup failures.

## Required device QA before release

This Windows development environment does not substitute for real Android/iOS QA.

1. Fresh installation: create PIN; import image/PDF; reopen and verify content.
2. Configure device passcode with and without biometrics. Unlock with each supported
   option; cancel OS prompts; reset forgotten PIN; verify old PIN no longer works.
3. Open viewer/editor/settings, a dialog, and a date picker. Wait past timeout and
   background/resume. Verify lock covers them and a draft survives authentication.
4. Export on Android, iPhone and iPad; check receiver access and delayed cleanup.
   Cancel the share sheet; verify no success claim or abandoned staging remains.
5. Save a recovery backup in Files/document-provider storage. On another installation,
   restore into an empty vault; compare bytes, titles, notes, categories and dates.
   Test wrong password, damaged package, nonempty vault and insufficient storage.
6. Notification permission denial must not imply a document failed to save.
   Verify generic notifications, title opt-in, reboot/timezone behavior and old
   artwork removal. Verify privacy settings against actual lock-screen display.
7. Validate keyboard-open and large-text layout on small phones and iPad.

## Not delivered in this phase

Trash/retention, previous versions, tags, OCR, configurable reminder offsets,
streaming large backups, authenticated migration of existing document blobs,
metadata encryption, integrity repair/cleanup queue, and a production signing
configuration remain roadmap work. PIN/device recovery cannot recover a missing
vault encryption key; a usable independent backup is required.
