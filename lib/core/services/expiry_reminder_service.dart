import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/documents/data/models/vault_document_model.dart';
import '../../features/documents/domain/entities/vault_document.dart';
import 'secure_storage_service.dart';

/// Schedules local notifications at 30, 15, and 7 days before document expiry
/// (09:00 local), with fallbacks when those offsets are already in the past.
class ExpiryReminderService {
  ExpiryReminderService({
    required Isar isar,
    required FlutterLocalNotificationsPlugin plugin,
    required SecureStorageService secureStorage,
  }) : _isar = isar,
       _plugin = plugin,
       _secureStorage = secureStorage;

  final Isar _isar;
  final FlutterLocalNotificationsPlugin _plugin;
  final SecureStorageService _secureStorage;

  static const String _channelId = 'document_expiry_v2';
  static const List<int> _daysBefore = [30, 15, 7];
  static const int _hour = 9;
  static const int _minute = 0;

  static bool _timeZonesInitialized = false;

  static Future<void> ensureLocalTimeZone() async {
    if (_timeZonesInitialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timeZonesInitialized = true;
  }

  /// Stable notification ids per document: three slots (30 / 15 / 7 day offsets).
  static int notificationId(int documentId, int index) =>
      documentId * 10 + index;

  Future<void> cancelForDocument(int documentId) async {
    for (var i = 0; i < _daysBefore.length; i++) {
      await _plugin.cancel(id: notificationId(documentId, i));
    }
  }

  /// Removes decrypted preview image written for notifications (if any).
  Future<void> deleteNotificationPreviewForDocument(int documentId) async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'notif_previews'));
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith('doc_$documentId.')) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> rescheduleForDocument(VaultDocument document) async {
    await cancelForDocument(document.id);
    await deleteNotificationPreviewForDocument(document.id);
    final expiry = document.expiryDate;
    if (expiry == null) return;
    final enabled = await _secureStorage.getExpiryRemindersEnabled();
    if (!enabled) return;
    await ensureLocalTimeZone();

    final private = await _secureStorage.getPrivateNotifications();
    final title = private || document.title.trim().isEmpty
        ? 'A document'
        : document.title.trim();
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    final now = tz.TZDateTime.now(tz.local);
    final notificationDetails = _notificationDetailsDefault();

    var scheduledAny = false;
    for (var i = 0; i < _daysBefore.length; i++) {
      final days = _daysBefore[i];
      final reminderDay = expiryDate.subtract(Duration(days: days));
      final scheduled = tz.TZDateTime(
        tz.local,
        reminderDay.year,
        reminderDay.month,
        reminderDay.day,
        _hour,
        _minute,
      );
      if (!scheduled.isAfter(now)) continue;

      scheduledAny = true;
      final body =
          '$title expires in $days day${days == 1 ? '' : 's'} (${_formatDate(expiryDate)}).';

      await _plugin.zonedSchedule(
        id: notificationId(document.id, i),
        scheduledDate: scheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expiry reminder',
        body: body,
      );
    }

    if (!scheduledAny) {
      await _scheduleProductionFallback(
        document: document,
        expiryDate: expiryDate,
        now: now,
        notificationDetails: notificationDetails,
      );
    }
  }

  /// When 30/15/7-day pings are all in the past (e.g. expiry is tomorrow or
  /// today), still schedule at least one useful reminder.
  Future<void> _scheduleProductionFallback({
    required VaultDocument document,
    required DateTime expiryDate,
    required tz.TZDateTime now,
    required NotificationDetails notificationDetails,
  }) async {
    final private = await _secureStorage.getPrivateNotifications();
    final title = private || document.title.trim().isEmpty
        ? 'A document'
        : document.title.trim();
    final morningOnExpiryDay = tz.TZDateTime(
      tz.local,
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      _hour,
      _minute,
    );

    if (morningOnExpiryDay.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: notificationId(document.id, 0),
        scheduledDate: morningOnExpiryDay,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expiry reminder',
        body:
            'Reminder: $title expires on ${_formatDate(expiryDate)} (this morning’s date reminder).',
      );
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final isExpiryToday =
        expiryDate.year == today.year &&
        expiryDate.month == today.month &&
        expiryDate.day == today.day;

    if (isExpiryToday) {
      final soon = now.add(const Duration(seconds: 90));
      await _plugin.zonedSchedule(
        id: notificationId(document.id, 0),
        scheduledDate: soon,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expires today',
        body: '$title expires today (${_formatDate(expiryDate)}).',
      );
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  NotificationDetails _notificationDetailsDefault() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Document expiry reminders',
        channelDescription: 'Notifications for upcoming document expiry dates.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Cancels all expiry notifications, then reschedules from DB (call on startup).
  Future<void> syncAll() async {
    // Remove plaintext artwork left by earlier versions, including documents
    // whose expiry was cleared or whose reminders were disabled.
    final base = await getApplicationSupportDirectory();
    final previews = Directory(p.join(base.path, 'notif_previews'));
    if (await previews.exists()) {
      await for (final entry in previews.list(followLinks: false)) {
        if (entry is File) await entry.delete();
      }
    }
    final models = await _isar
        .collection<VaultDocumentModel>()
        .filter()
        .expiryDateIsNotNull()
        .findAll();

    for (final m in models) {
      await cancelForDocument(m.id);
    }

    final enabled = await _secureStorage.getExpiryRemindersEnabled();
    if (!enabled) return;

    await ensureLocalTimeZone();
    for (final m in models) {
      await rescheduleForDocument(m.toEntity());
    }
  }
}
