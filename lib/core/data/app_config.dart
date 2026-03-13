import 'package:isar/isar.dart';

part 'app_config.g.dart';

@collection
class AppConfig {
  AppConfig();

  Id id = Isar.autoIncrement;

  // Reserved for future global settings.
  bool dummy = false;
}

