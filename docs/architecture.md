## Offline Personal Document Vault – Architecture

### Overview

- **Framework**: Flutter
- **State management**: `provider`
- **Storage**:
  - Structured data: Isar (`isar`, `isar_flutter_libs`)
  - Encrypted files: app documents directory (`path_provider`)
  - Secrets/keys: `flutter_secure_storage`
- **Security & platform**
  - Biometrics: `local_auth`
  - Local notifications: `flutter_local_notifications`

### Layers

- **core/**
  - Cross-cutting services and initialization logic.
  - No UI; pure Dart services and models.
- **data/** (to be added in later modules)
  - Isar collections, repositories for documents, categories, settings.
- **features/** (to be added in later modules)
  - UI screens and widgets grouped by feature/module.
- **providers/**
  - `ChangeNotifier` classes used with `provider` for app state.

### Startup flow

1. `main.dart`
   - Ensures Flutter bindings are initialized.
   - Creates a single `AppInitializer` instance.
   - Wraps the app with `ChangeNotifierProvider<AppInitProvider>`.
   - Immediately calls `AppInitProvider.initialize()`.
2. `AppInitProvider`
   - Exposes `AppInitStatus` (`idle`, `loading`, `ready`, `error`) and `AppInitResult`.
   - Drives the splash screen / error screen / root navigation.
3. `AppInitializer`
   - Coordinates:
     - Secure storage (encryption key + first launch).
     - Vault directory creation.
     - Isar database opening.
     - Biometric capability detection.
     - Local notifications initialization.
   - Returns an `AppInitResult` snapshot for the rest of the app to use.

### Error handling

- All startup work is wrapped in `AppInitializer.initialize()`.
- On any thrown error:
  - `AppInitResult.fatalError` is set.
  - `AppInitProvider` sets status to `error`.
  - `_InitErrorScreen` displays a friendly message with an optional error string and a **Retry** button.

### Extensibility

- New services that must be ready before the UI (e.g. analytics, crash reporting, remote config) should:
  - Be added as dependencies in `AppInitializer`.
  - Be initialized in order inside `initialize()`.
  - Surface any configuration flags through `AppInitResult` or a dedicated provider.

