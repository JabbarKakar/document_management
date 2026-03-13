import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/init/app_init_result.dart';
import 'core/init/app_initializer.dart';
import 'core/providers/app_init_provider.dart';
import 'core/services/encrypted_file_storage_service.dart';
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
        final fileStorage = EncryptedFileStorageService(vaultPath);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<DocumentListProvider>(
              create: (_) => DocumentListProvider(
                IsarDocumentRepository(
                  isar: isar,
                  fileStorageService: fileStorage,
                ),
              )..loadDocuments(),
            ),
            ChangeNotifierProvider<CategoryListProvider>(
              create: (_) =>
                  CategoryListProvider(IsarCategoryRepository(isar))
                    ..loadAndEnsureDefaults(),
            ),
          ],
          child: const DocumentsHomeScreen(),
        );
    }
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

class _RootHomePlaceholder extends StatelessWidget {
  const _RootHomePlaceholder({required this.result});

  final AppInitResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Personal Document Vault'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Initialization complete.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('First launch: ${result.isFirstLaunch}'),
            Text('Biometric available: ${result.biometricAvailable}'),
            Text('Vault directory: ${result.appDocumentsPath}'),
          ],
        ),
      ),
    );
  }
}