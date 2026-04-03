import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_manager.dart';
import 'core/init/app_init_result.dart';
import 'core/init/app_initializer.dart';
import 'core/providers/app_init_provider.dart';
import 'core/encryption/vault_encryption_service.dart';
import 'core/services/encrypted_file_storage_service.dart';
import 'core/services/expiry_reminder_service.dart';
import 'core/services/secure_storage_service.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'features/auth/presentation/screens/create_pin_screen.dart';
import 'features/auth/presentation/screens/lock_screen.dart';
import 'features/documents/data/repositories/isar_document_repository.dart';
import 'features/documents/presentation/providers/document_list_provider.dart';
import 'features/documents/presentation/screens/documents_home_screen.dart';
import 'features/categories/data/repositories/isar_category_repository.dart';
import 'features/categories/presentation/providers/category_list_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initializer = AppInitializer();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppInitializer>.value(value: initializer),
        ChangeNotifierProvider<AppInitProvider>(
          create: (_) => AppInitProvider(initializer)..initialize(),
        ),
      ],
      child: const OfflineDocumentVaultApp(),
    ),
  );
}

class OfflineDocumentVaultApp extends StatelessWidget {
  const OfflineDocumentVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Personal Document Vault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AppInitGate(),
    );
  }
}

class _AppInitGate extends StatefulWidget {
  const _AppInitGate();

  @override
  State<_AppInitGate> createState() => _AppInitGateState();
}

class _AppInitGateState extends State<_AppInitGate> {
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3)).then((_) {
      if (mounted) {
        setState(() {
          _minSplashElapsed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initProvider = context.watch<AppInitProvider>();

    switch (initProvider.status) {
      case AppInitStatus.idle:
      case AppInitStatus.loading:
        return const SplashScreen();
      case AppInitStatus.error:
        return _InitErrorScreen(
          result: initProvider.result,
          onRetry: () => initProvider.initialize(),
        );
      case AppInitStatus.ready:
        final result = initProvider.result;
        if (!_minSplashElapsed || result == null) {
          return const SplashScreen();
        }

        final initializer = context.read<AppInitializer>();
        final isar = initializer.isar;
        if (isar == null) {
          return _InitErrorScreen(
            result: result,
            onRetry: () => initProvider.initialize(),
          );
        }

        final vaultPath = result.appDocumentsPath;
        final vaultEncryption = VaultEncryptionService(SecureStorageService());
        final fileStorage = EncryptedFileStorageService(
          vaultPath,
          vaultEncryption,
        );

        final expiryReminders = ExpiryReminderService(
          isar: isar,
          plugin: initializer.notificationInitializer.plugin,
          secureStorage: initializer.secureStorage,
        );

        final mainContent = MultiProvider(
          providers: [
            Provider<VaultEncryptionService>.value(value: vaultEncryption),
            Provider<EncryptedFileStorageService>.value(value: fileStorage),
            Provider<SecureStorageService>.value(value: initializer.secureStorage),
            Provider<ExpiryReminderService>.value(value: expiryReminders),
            ChangeNotifierProvider<DocumentListProvider>(
              create: (_) => DocumentListProvider(
                IsarDocumentRepository(
                  isar: isar,
                  fileStorageService: fileStorage,
                ),
                expiryReminders,
              )..loadDocuments(),
            ),
            ChangeNotifierProvider<CategoryListProvider>(
              create: (_) =>
                  CategoryListProvider(IsarCategoryRepository(isar))
                    ..loadAndEnsureDefaults(),
            ),
          ],
          child: _ExpiryBootstrap(
            service: expiryReminders,
            child: const DocumentsHomeScreen(),
          ),
        );

        return ChangeNotifierProvider<AuthStateProvider>(
          create: (_) {
            final authManager = AuthManager();
            final p = AuthStateProvider(authManager: authManager);
            p.init();
            return p;
          },
          child: _AuthGate(mainContent: mainContent),
        );
    }
  }
}

class _ExpiryBootstrap extends StatefulWidget {
  const _ExpiryBootstrap({required this.service, required this.child});

  final ExpiryReminderService service;
  final Widget child;

  @override
  State<_ExpiryBootstrap> createState() => _ExpiryBootstrapState();
}

class _ExpiryBootstrapState extends State<_ExpiryBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.service.syncAll());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.mainContent});

  final Widget mainContent;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStateProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authProvider == null) {
      _authProvider = context.read<AuthStateProvider>();
      WidgetsBinding.instance.addObserver(_authProvider!);
    }
  }

  @override
  void dispose() {
    if (_authProvider != null) {
      WidgetsBinding.instance.removeObserver(_authProvider!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStateProvider>();
    if (auth.needsPinSetup) {
      return const CreatePinScreen();
    }
    if (auth.isLocked) {
      return const LockScreen();
    }
    return widget.mainContent;
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({
    required this.result,
    required this.onRetry,
  });

  final AppInitResult? result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Unable to start the vault.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please try again. If the problem persists, restart the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (result?.fatalError != null)
                Text(
                  result!.fatalError.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}