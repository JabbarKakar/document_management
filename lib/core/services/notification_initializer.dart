import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationInitializer {
  NotificationInitializer() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    const androidChannel = AndroidNotificationChannel(
      'expiry_reminders',
      'Document expiry reminders',
      description: 'Notifications for upcoming document expiry dates.',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }
}

