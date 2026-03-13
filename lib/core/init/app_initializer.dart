import 'dart:math';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import '../data/app_config.dart';
import '../services/app_directory_service.dart';
import '../../features/documents/data/models/vault_document_model.dart';
import '../../features/categories/data/models/vault_category_model.dart';
import '../services/auth_initializer.dart';
import '../services/notification_initializer.dart';
import '../services/secure_storage_service.dart';
import 'app_init_result.dart';

class AppInitializer {
  AppInitializer({
    SecureStorageService? secureStorageService,
    AppDirectoryService? appDirectoryService,
    AuthInitializer? authInitializer,
    NotificationInitializer? notificationInitializer,
  })  : _secureStorageService =
            secureStorageService ?? SecureStorageService(),
        _appDirectoryService =
            appDirectoryService ?? const AppDirectoryService(),
        _authInitializer = authInitializer ?? AuthInitializer(),
        _notificationInitializer =
            notificationInitializer ?? NotificationInitializer();

  final SecureStorageService _secureStorageService;
  final AppDirectoryService _appDirectoryService;
  final AuthInitializer _authInitializer;
  final NotificationInitializer _notificationInitializer;

  Isar? _isar;

  Isar? get isar => _isar;

  Future<AppInitResult> initialize() async {
    try {
      final appDocsDir = await _appDirectoryService.getAppDocumentsDirectory();

      await _ensureEncryptionKey();

      _isar = await Isar.open(
        [
          AppConfigSchema,
          VaultDocumentModelSchema,
          VaultCategoryModelSchema,
        ],
        directory: p.normalize(appDocsDir.path),
      );

      final biometricAvailable = await _authInitializer.canCheckBiometrics();

      await _notificationInitializer.initialize();

      final isFirstLaunch = await _secureStorageService.isFirstLaunch();
      if (isFirstLaunch) {
        await _secureStorageService.markLaunched();
      }

      return AppInitResult(
        isFirstLaunch: isFirstLaunch,
        biometricAvailable: biometricAvailable,
        appDocumentsPath: appDocsDir.path,
      );
    } catch (error) {
      return AppInitResult(
        isFirstLaunch: false,
        biometricAvailable: false,
        appDocumentsPath: '',
        fatalError: error,
      );
    }
  }

  Future<void> _ensureEncryptionKey() async {
    final existing = await _secureStorageService.readEncryptionKey();
    if (existing != null && existing.isNotEmpty) {
      return;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorageService.writeEncryptionKey(key);
  }
}

