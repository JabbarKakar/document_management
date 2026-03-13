class AppInitResult {
  const AppInitResult({
    required this.isFirstLaunch,
    required this.biometricAvailable,
    required this.appDocumentsPath,
    this.fatalError,
  });

  final bool isFirstLaunch;
  final bool biometricAvailable;
  final String appDocumentsPath;
  final Object? fatalError;

  bool get hasError => fatalError != null;
}

