## Module 1 – App Initialization

### Objective

Prepare the application environment **before** any main UI loads:

- Initialize the local database.
- Initialize encryption services and keys.
- Configure directories for encrypted document storage.
- Initialize biometric and notification services.
- Handle first-time launch.

### Key classes & files

- `lib/core/init/app_init_result.dart`
  - Immutable result object for startup:
    - `bool isFirstLaunch`
    - `bool biometricAvailable`
    - `String appDocumentsPath`
    - `Object? fatalError`
- `lib/core/services/secure_storage_service.dart`
  - Wrapper around `flutter_secure_storage`.
  - Manages:
    - `encryption_key` – persisted AES key (stored as hex string).
    - `has_run_before` – simple first-launch flag.
- `lib/core/services/app_directory_service.dart`
  - Uses `path_provider` to create and return the `vault_documents` directory under the app documents directory.
- `lib/core/services/notification_initializer.dart`
  - Configures `FlutterLocalNotificationsPlugin`.
  - Creates Android channel `expiry_reminders` for document expiry notifications.
- `lib/core/services/auth_initializer.dart`
  - Wraps `LocalAuthentication`.
  - Exposes `canCheckBiometrics()` to detect biometric capability.
- `lib/core/init/app_initializer.dart`
  - Central orchestrator for startup.
  - Responsibilities:
    - Ensure encryption key exists (generate 32-byte random key if missing).
    - Resolve and create app documents directory.
    - Open Isar database (schemas will be registered in later modules).
    - Detect biometric support.
    - Initialize local notifications.
    - Detect and mark first launch.
  - Returns `AppInitResult` with consolidated info.
- `lib/core/providers/app_init_provider.dart`
  - `ChangeNotifier` used with `provider`.
  - Exposes:
    - `AppInitStatus status` (`idle`, `loading`, `ready`, `error`)
    - `AppInitResult? result`
  - Method: `Future<void> initialize()` which:
    - Sets status to `loading`.
    - Calls `AppInitializer.initialize()`.
    - Updates status to `ready` or `error` based on `result.hasError`.
- `lib/main.dart`
  - Entry point of the application.
  - Wraps app with `ChangeNotifierProvider<AppInitProvider>`.
  - Uses `_AppInitGate` to switch between:
    - Splash screen while loading.
    - Error screen on failure.
    - Placeholder home on success.

### Initialization sequence

1. **Flutter binding**
   - `WidgetsFlutterBinding.ensureInitialized();`
2. **Provider bootstrapping**
   - Create `AppInitializer`.
   - Provide `AppInitProvider` with `ChangeNotifierProvider`.
   - Immediately call `initialize()` in the provider constructor.
3. **Directory setup**
   - `AppDirectoryService.getAppDocumentsDirectory()`:
     - Gets the base application documents directory.
     - Ensures `vault_documents` folder exists.
4. **Encryption key management**
   - `SecureStorageService.readEncryptionKey()`:
     - If no key found, `_ensureEncryptionKey()` generates a 32-byte random key and stores it as hex.
5. **Database initialization**
   - Open Isar with the vault directory as `directory`.
   - No schemas yet; they will be added in Modules 2–3.
6. **Biometric capability**
   - `AuthInitializer.canCheckBiometrics()`:
     - Uses `LocalAuthentication.canCheckBiometrics` and `isDeviceSupported()`.
7. **Notification setup**
   - `NotificationInitializer.initialize()`:
     - Initializes plugin.
     - Creates `expiry_reminders` Android channel.
8. **First launch detection**
   - `SecureStorageService.isFirstLaunch()` and `markLaunched()`:
     - Determines if this is the first run and stores the flag.
9. **Result**
   - Pack all data into `AppInitResult` and return.

### UI behavior

- **Splash screen**
  - `_SplashScreen` shows a loader and text “Preparing your secure vault...” while `status` is `idle`/`loading`.
- **Error screen**
  - `_InitErrorScreen` appears if `status` is `error`.
  - Shows a generic message, optional error string, and a **Retry** button that re-calls `initialize()`.
- **Placeholder home**
  - `_RootHomePlaceholder` is displayed when `status` is `ready`.
  - Shows:
    - `isFirstLaunch`
    - `biometricAvailable`
    - `appDocumentsPath`
  - This will later be replaced by the real navigation (lock screen / vault home).

### How to extend this module

- **Add new startup services** (e.g., settings preload, crash reporting):
  - Add dependencies to `AppInitializer` constructor.
  - Initialize them in order inside `initialize()`.
  - Expose any values needed by the UI or other modules through:
    - `AppInitResult`, or
    - Additional providers created after initialization.
- **Add schemas to Isar**:
  - In later modules, define Isar collection classes and register their `schemas` when calling `Isar.open`.
- **Integrate with app lock (Module 6)**:
  - When the Security & Authentication module is built, `_AppInitGate` should route to:
    - Lock screen if vault is protected.
    - Vault home directly otherwise.

