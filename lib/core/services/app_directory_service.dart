import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDirectoryService {
  const AppDirectoryService();

  Future<Directory> getAppDocumentsDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${baseDir.path}${Platform.pathSeparator}vault_documents');
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    return documentsDir;
  }
}

