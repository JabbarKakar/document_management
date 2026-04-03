import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:isar/isar.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/documents/data/models/vault_document_model.dart';
import '../../features/documents/domain/entities/vault_document.dart';
import 'secure_storage_service.dart';

/// Schedules local notifications at 30, 15, and 7 days before document expiry.
///
/// In **debug** builds only, schedules three test notifications at 15s, 45s, and
/// 75s from schedule time (ignores day offsets and 09:00) so you can verify
/// without waiting.
class ExpiryReminderService {
  ExpiryReminderService({
    required Isar isar,
    required FlutterLocalNotificationsPlugin plugin,
    required SecureStorageService secureStorage,
  })  : _isar = isar,
        _plugin = plugin,
        _secureStorage = secureStorage;

  final Isar _isar;
  final FlutterLocalNotificationsPlugin _plugin;
  final SecureStorageService _secureStorage;

  static const String _channelId = 'document_expiry_v2';
  static const List<int> _daysBefore = [30, 15, 7];
  static const int _hour = 9;
  static const int _minute = 0;

  /// Debug-only: seconds from "now" for each of the three test notifications.
  static const List<int> _debugOffsetsSeconds = [10, 30, 55];

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
  static int notificationId(int documentId, int index) => documentId * 10 + index;

  Future<void> cancelForDocument(int documentId) async {
    final count =
        kDebugMode ? _debugOffsetsSeconds.length : _daysBefore.length;
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(id: notificationId(documentId, i));
    }
  }

  Future<void> rescheduleForDocument(VaultDocument document) async {
    await cancelForDocument(document.id);
    final expiry = document.expiryDate;
    if (expiry == null) return;
    final enabled = await _secureStorage.getExpiryRemindersEnabled();
    if (!enabled) return;
    await ensureLocalTimeZone();

    final title = document.title.trim().isEmpty ? 'Document' : document.title.trim();
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    final now = tz.TZDateTime.now(tz.local);

    if (kDebugMode) {
      for (var i = 0; i < _debugOffsetsSeconds.length; i++) {
        final secs = _debugOffsetsSeconds[i];
        final scheduled = now.add(Duration(seconds: secs));
        final body =
            '[TEST] $title — expiry ${_formatDate(expiryDate)}. '
            'Fires in ~${secs}s (${i + 1}/3). Release uses 30/15/7 days at 09:00.';
        await _plugin.zonedSchedule(
          id: notificationId(document.id, i),
          scheduledDate: scheduled,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: 'Document expiry reminder (debug)',
          body: body,
        );
      }
      return;
    }

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
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expiry reminder',
        body: body,
      );
    }

    if (!scheduledAny) {
      await _scheduleProductionFallback(
        documentId: document.id,
        title: title,
        expiryDate: expiryDate,
        now: now,
      );
    }
  }

  /// When 30/15/7-day pings are all in the past (e.g. expiry is tomorrow or
  /// today), still schedule at least one useful reminder.
  Future<void> _scheduleProductionFallback({
    required int documentId,
    required String title,
    required DateTime expiryDate,
    required tz.TZDateTime now,
  }) async {
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
        id: notificationId(documentId, 0),
        scheduledDate: morningOnExpiryDay,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expiry reminder',
        body:
            'Reminder: $title expires on ${_formatDate(expiryDate)} (this morning’s date reminder).',
      );
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final isExpiryToday = expiryDate.year == today.year &&
        expiryDate.month == today.month &&
        expiryDate.day == today.day;

    if (isExpiryToday) {
      final soon = now.add(const Duration(seconds: 90));
      await _plugin.zonedSchedule(
        id: notificationId(documentId, 0),
        scheduledDate: soon,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Document expires today',
        body: '$title expires today (${_formatDate(expiryDate)}).',
      );
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      'Document expiry reminders',
      channelDescription: 'Notifications for upcoming document expiry dates.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  /// Cancels all expiry notifications, then reschedules from DB (call on startup).
  Future<void> syncAll() async {
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
