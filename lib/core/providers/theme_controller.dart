import 'package:flutter/material.dart';

import '../services/secure_storage_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  final SecureStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final s = await _storage.getThemeModePreference();
    _themeMode = switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _storage.setThemeModePreference(key);
    notifyListeners();
  }
}
