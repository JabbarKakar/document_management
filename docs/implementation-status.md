# Implementation status — 26 September 2026

The product remains a personal, offline Android/iOS vault. This page records
implemented behavior; the numbered module documents also contain future ideas.

## Implemented

| Area | Current behavior |
|---|---|
| Unlock/recovery | PIN or independent OS credentials; fresh device authentication for forgotten-PIN reset; portable password-encrypted recovery backups |
| Session security | Entire protected navigation stack locks, including dialogs; real idle timer; cache invalidation and execution-time access checks |
| File protection | Authenticated AES-256-GCM for new files; CBC compatibility reader; explicit copy/verify/commit migration in Settings → Vault health |
| Private text | Titles, notes, tags, extracted text and activity are encrypted on new writes and maintenance upgrades |
| Organization/search | Categories, tags, favorites, cached search, file/expiry/tag filters, fixed smart views for favorites/recent/uncategorized/expiry attention |
| Trash | Delete moves to Trash; restore or confirmed permanent deletion; automatic expiry after 30 days, checked on startup/Trash opening |
| Versions | Retain the previous three files; preview or restore a prior file without changing current title/notes/tags/expiry |
| Backups | V2 logical format includes Trash, prior files and organization; V1 packages still readable; restore uses fresh paths and destination device keys |
| Export | Plaintext share after explicit choice, or a password-protected selected-document package; selection packages omit prior files and activity |
| Imports | File signatures, size limits, image dimension checks; bounded file reads, progress, stop-after-current-file and retry of failed/unprocessed items |
| Scanner | Processed previews, rotation, manual edge cropping, ordering, explicit multipage PDF output; image work runs outside the UI isolate |
| Text extraction | User-triggered on-device English/Latin OCR for images and PDFs; encrypted text becomes searchable; cancellation and lock checks |
| Reminders | Private titles by default; no image attachments; up to five per-document offsets; disable per document; permission retry; calendar-day boundary fixes |
| Activity | Up to 200 local events per document, including prepared exports; this is not a tamper-proof audit log |
| Maintenance | Verify referenced current/prior files; resumable upgrade; preserve unreadable records; confirmed cleanup of unreferenced generated files older than 24 hours |
| Offline design | Existing Inter font bundled locally; Android release manifest removes Internet permission; responsive design tokens retained |

## Limits and upgrade behavior

- Packages: 1,000 documents, 32 MiB total file content (including versions),
  48 MiB encrypted package. These are bounded in-memory packages, not streaming archives.
- Restore requires an empty vault. It does not merge into an existing collection.
  Restored Trash receives a fresh 30-day recovery window.
- Imports: 20 MiB per file, 50 files/64 MiB per batch; decoded common images up to
  40 megapixels/100 frames. HEIC has signature validation but remains dependent
  on native platform decoding. PDF signature/trailer checks are not malware scanning.
- OCR: 20 MiB and 20 PDF pages; English/Latin first. It is approximate and must be
  reviewed. Android bundles ML Kit's Latin model; iOS uses Apple Vision. No OCR
  images are written to temporary files. Native accuracy still needs device QA.
- Old CBC files remain readable but lack authentication until upgraded. Legacy
  plaintext files require Settings → Vault health before viewing. The upgrade
  needs temporary space and never destroys an original before a verified commit.
- Category names, dates, IDs, version pointers and structural metadata remain in
  Isar. Old database pages can retain earlier plaintext. This is not whole-database
  encryption or guaranteed secure erasure on flash storage.
- Missing device keys require an independent recovery backup; neither the vault
  PIN nor an OS passcode can recover a lost encryption key.
- Android expiry notifications use approximate scheduling around 09:00 to avoid
  requiring special exact-alarm access. OS permission, battery restrictions and
  platform notification limits still apply.
- Unreferenced cleanup is explicit and conservative: database files, unknown
  filenames, recent staging files, Trash and retained versions are excluded.

## Validation and release gates

Latest validation: static analysis reports no issues, all 32 automated tests
passed with native Isar integration enabled, and the Android debug APK built successfully. The build still reports
upcoming support warnings for the pinned Gradle/AGP/Kotlin versions; their coordinated
upgrade is a separate build-tool maintenance task, not a failed build.

Run `flutter analyze` and `flutter test`. Native Isar integration tests require
`ISAR_TEST_LIBRARY` to point to the matching Isar 3.1 Windows DLL; without it the
native integration test is explicitly skipped. The test exercises real database
replacement/version restore/Trash/backup/restore/migration and orphan cleanup.

Additional tests cover auth, lock boundaries, crypto tampering, metadata binding,
staged-file failure handling, import rejection, OCR results arriving after lock,
calendar/retention boundaries and scanner layout with large text.

Before release, use real Android and iOS devices to verify OS authentication,
notifications (permission denial/timezone/reboot), camera/OCR accuracy, file
providers, cross-device recovery, accessibility and low-storage interruptions.
An iOS build requires macOS/Xcode; it has not been validated on this Windows host.
Production application identifiers, Android signing keys and Apple signing/team
configuration still need the owner's release settings.

## Later enhancements, not release-complete claims

Automatic perspective correction, additional OCR scripts, streaming large
backups, merge restore, whole-database encryption/compaction, user-defined smart
folders and a separate analytics dashboard remain optional follow-up work.
Cloud sync, team approval workflows and desktop features are outside the agreed
personal/offline Android/iOS scope.

## Native implementation references

- [Bundled Android text recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)
- [Apple Vision text recognition](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Inter font source and SIL Open Font License](https://github.com/google/fonts/tree/main/ofl/inter)
