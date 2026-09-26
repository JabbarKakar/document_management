import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:document_management/core/theme/app_theme.dart';
import 'package:document_management/core/providers/theme_controller.dart';
import 'package:document_management/core/services/document_thumbnail_cache_service.dart';
import 'package:document_management/core/services/encrypted_file_storage_service.dart';
import 'package:document_management/core/services/expiry_reminder_service.dart';
import 'package:document_management/core/services/secure_storage_service.dart';
import 'package:document_management/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:document_management/features/auth/presentation/screens/lock_screen.dart';
import 'package:document_management/features/categories/domain/entities/vault_category.dart';
import 'package:document_management/features/categories/domain/repositories/category_repository.dart';
import 'package:document_management/features/categories/presentation/providers/category_list_provider.dart';
import 'package:document_management/features/documents/domain/entities/vault_document.dart';
import 'package:document_management/features/documents/domain/repositories/document_repository.dart';
import 'package:document_management/features/documents/presentation/providers/document_list_provider.dart';
import 'package:document_management/features/documents/presentation/screens/documents_home_screen.dart';
import 'package:document_management/features/settings/presentation/screens/settings_screen.dart';
import 'support/auth_fakes.dart';
import 'package:document_management/features/documents/presentation/screens/edit_document_screen.dart';
import 'package:document_management/features/categories/presentation/screens/category_management_screen.dart';

class _Picker extends FilePicker {}

class _Documents extends Fake implements DocumentRepository {
  @override
  Future<List<VaultDocument>> getAllDocuments() async => [
    for (final (index, title) in [
      'Passport',
      'Home insurance',
      'University degree',
      'Travel itinerary',
    ].indexed)
      VaultDocument(
        id: index + 1,
        title: title,
        filePath: '/fixture/$index',
        createdAt: DateTime(2026, 9, 20 - index),
        fileType: VaultDocumentFileType.pdf,
        categoryId: 1,
        isFavorite: index == 0,
        expiryDate: index == 1
            ? DateTime.now().add(const Duration(days: 14))
            : null,
      ),
  ];
}

class _Categories extends Fake implements CategoryRepository {
  @override
  Future<void> ensureDefaultCategories() async {}
  @override
  Future<List<VaultCategory>> getAllCategories() async => [
    VaultCategory(id: 1, name: 'Personal', isDefault: true, sortOrder: 0),
  ];
}

class _Reminders extends Fake implements ExpiryReminderService {}

class _Files extends Fake implements EncryptedFileStorageService {
  @override
  Future<Uint8List> readDecryptedBytes(String path) async =>
      throw StateError('Fixture has no file');
}

class _Preferences extends MemorySecurityStorage {
  @override
  Future<bool> getExpiryRemindersEnabled() async => true;
  @override
  Future<bool> getPrivateNotifications() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FilePicker.platform = _Picker();
    final fonts = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final config in [
    (name: 'dark-phone', size: const Size(390, 844), scale: 1.0, dark: true),
    (name: 'light-phone', size: const Size(390, 844), scale: 1.0, dark: false),
    (name: 'large-text', size: const Size(320, 740), scale: 2.0, dark: true),
    (name: 'tablet', size: const Size(1100, 900), scale: 1.0, dark: true),
  ]) {
    testWidgets('library, search, grid and unlock at ${config.name}', (
      tester,
    ) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = _Preferences();
      final auth = AuthStateProvider(
        authManager: FakeAuthManager(),
        secureStorageService: storage,
      );
      await auth.init();
      final cache = DocumentThumbnailCacheService();
      final docs = DocumentListProvider(
        _Documents(),
        _Reminders(),
        storage,
        cache,
      );
      await docs.loadDocuments();
      final categories = CategoryListProvider(_Categories());
      await categories.loadAndEnsureDefaults();
      final theme = ThemeController(storage);
      final boundary = GlobalKey();
      Widget app(Widget screen) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: docs),
          ChangeNotifierProvider.value(value: categories),
          ChangeNotifierProvider.value(value: theme),
          Provider<SecureStorageService>.value(value: storage),
          Provider<ExpiryReminderService>.value(value: _Reminders()),
          Provider<EncryptedFileStorageService>.value(value: _Files()),
          Provider.value(value: cache),
        ],
        child: MaterialApp(
          theme: config.dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(config.scale)),
            child: RepaintBoundary(key: boundary, child: child),
          ),
          home: screen,
        ),
      );

      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('UI_PREVIEWS')) return;
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final folder = Directory('build/ui-preview')
            ..createSync(recursive: true);
          File(
            '${folder.path}/${config.name}-$name.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(app(const DocumentsHomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('library');
      await tester.enterText(find.byType(TextField).first, 'Passport');
      await tester.pumpAndSettle();
      expect(docs.documents.length, 1);
      expect(find.text('4 documents stored locally.'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(docs.documents.length, 4);
      await tester.dragUntilVisible(
        find.byTooltip('Grid view').hitTestable(),
        find.byType(CustomScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Grid view'));
      expect(find.byTooltip('Grid view').hitTestable(), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('grid');

      await tester.pumpWidget(app(const EditDocumentScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('add');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(const CategoryManagementScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('categories');
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('settings');
      await tester.pumpWidget(app(const LockScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('lock');
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      docs.dispose();
      categories.dispose();
      theme.dispose();
    });
  }
}
