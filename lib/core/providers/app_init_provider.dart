import 'package:flutter/foundation.dart';

import '../init/app_init_result.dart';
import '../init/app_initializer.dart';

enum AppInitStatus { idle, loading, ready, error }

class AppInitProvider extends ChangeNotifier {
  AppInitProvider(this._initializer);

  final AppInitializer _initializer;

  AppInitStatus _status = AppInitStatus.idle;
  AppInitResult? _result;

  AppInitStatus get status => _status;
  AppInitResult? get result => _result;

  Future<void> initialize() async {
    if (_status == AppInitStatus.loading || _status == AppInitStatus.ready) {
      return;
    }
    _status = AppInitStatus.loading;
    notifyListeners();

    final initResult = await _initializer.initialize();
    _result = initResult;
    _status = initResult.hasError ? AppInitStatus.error : AppInitStatus.ready;
    notifyListeners();
  }
}

