# Offline Document Vault

A personal, offline Flutter vault for **Android and iOS**. Documents are imported
from files, camera, gallery, or the multi-page scanner. Search, categories,
expiry reminders, image/PDF previews, bulk actions and file replacement are
available alongside tags, favorites, Trash, retained versions and offline OCR.
The existing Material 3 teal design supports light and dark modes, with bundled fonts.

## Development

Use a Flutter SDK supporting Dart 3.11 or later, Android tooling, and Xcode on a
Mac for iOS builds. From the project directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

If changing Isar models, regenerate the checked-in generated sources with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Do not replace document encryption keys or delete database/files to resolve a
startup problem. Android release signing still needs a production configuration.

## Unlock and forgotten PIN

New vault PINs contain 4–8 digits. Device passcode, fingerprint or Face ID is an
independent unlock method; biometric enrollment is not required for device
passcode authentication. The device must have usable OS authentication configured.
**Forgot PIN?** on the lock screen verifies device authentication before changing
the vault PIN, leaving document encryption keys and contents unchanged.

Legacy PIN hashes migrate on successful unlock. Existing longer PINs remain
usable. Failed PIN attempts have a persisted cooldown. The inactivity timer hides
all protected routes and dialogs, retaining in-memory drafts for the next unlock.

## Lost-device recovery

In **Settings → Backup & recovery**, create a `.dvbackup` file using a separate
recovery password (at least 12 characters). Save a copy somewhere accessible
without this device and keep the password separately. There is no online account
or recovery service. A PIN or device passcode cannot decrypt a recovery package.

On the replacement Android/iOS device, install the app, create a new vault PIN,
and restore from the same settings screen. Restore requires an empty vault and
never overwrites an existing collection. It imports document contents and metadata
under the new device's encryption key; device security preferences are not imported.

Recovery packages support **1,000 documents / 32 MiB of document content**, including retained versions,
and a maximum 48 MiB package. Missing/unreadable files fail backup creation.
Passwords cannot be recovered by this app. Test a restore before relying on a backup.

## Privacy and current limitations

- Private notifications are the default. Titles can be enabled in settings;
  document images are never attached. Old notification artwork is cleaned up.
- Export offers a selected password-protected package or decrypted copies after confirmation. Local plaintext staging is
  cleaned after a 10-minute receiver grace period or on the next cold start.
  Copies kept by receiving apps are outside the vault's control.
- Recovery packages use PBKDF2-HMAC-SHA256 (600,000 rounds), a random salt,
  AES-256-GCM and an authenticated version header. Password work runs off the UI isolate.
- New files use authenticated AES-256-GCM. **Settings → Vault health** upgrades
  older files and encrypts existing titles, notes, tags, extracted text and activity.
  Dates, category names and structural database metadata remain unencrypted.
- Delete moves documents to **30-day Trash**. Replacement retains **three previous
  files**. Restore and confirmed permanent deletion are available from Settings.
- Database/file transaction safety prefers an unreferenced encrypted file over
  a broken document. Vault health verifies files and offers confirmed cleanup of
  unused generated files older than 24 hours. No automatic orphan purge is performed.

Open a document's details, then **Tags, reminders & history**, to organize it,
extract searchable text, configure reminders or restore a prior file. OCR supports
English/Latin images and PDFs up to 20 pages. Scanner pages can be cropped, rotated
and reordered before export; previews show the selected enhancement.

See [implementation and device QA](docs/security-recovery-implementation.md) and
[current status, limits and remaining work](docs/implementation-status.md).
