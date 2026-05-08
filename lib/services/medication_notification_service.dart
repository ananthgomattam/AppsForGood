// This class was created with the help of Claude 4.6. It was prompted multiple times to ask how to integrate notifications
// into a Flutter app, and the final implementation was based on the suggestions provided by Claude. 
// The code was then adapted to fit the specific needs of the ForSeizure app, such as syncing medication reminders from the database and handling platform-specific initialization.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/medication.dart';
import '../database/database_helper.dart';

class MedicationNotificationService {
  MedicationNotificationService._();
  static final MedicationNotificationService instance =
      MedicationNotificationService._();

// Constants for the notification channel used for medication reminders, and the FlutterLocalNotificationsPlugin instance. 
// Also tracks whether the service has been initialized to avoid redundant initialization.
  static const String _channelId = 'medication_reminders';
  static const String _channelName = 'Medication Reminders';
  static const String _channelDescription =
      'Reminders to take scheduled medication';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize the notification service by setting up the FlutterLocalNotificationsPlugin with the appropriate settings for Android and iOS, initializing time zones, and requesting necessary permissions.
  // This is only done once and is skipped on web and Windows platforms where notifications are not supported.
  Future<void> initialize() async {
    if (_initialized || kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    try {
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  // Sync medication reminders by first ensuring the service is initialized, then canceling any existing medication reminders, 
  // fetching all medications from the database, and scheduling new reminders for each medication based on their specified times and dates.
  Future<void> syncMedicationReminders() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    if (!_initialized) {
      await initialize();
    }

    await _cancelMedicationRemindersOnly();

    final medications = await DatabaseHelper.instance.getAllMedications();
    for (final medication in medications) {
      await _scheduleMedication(medication);
    }
  }

  // Cancel medication reminders
  Future<void> _cancelMedicationRemindersOnly() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload == 'medication_reminder') {
        await _plugin.cancel(request.id);
      }
    }
  }

  // Schedule notifications for a given medication
  Future<void> _scheduleMedication(Medication medication) async {
    final int? medicationId = medication.id;
    if (medicationId == null) return;

    final now = DateTime.now();
    final startDate = DateTime.tryParse(medication.startDate);
    final endDate = medication.endDate == null || medication.endDate!.isEmpty
        ? null
        : DateTime.tryParse(medication.endDate!);

    if (endDate != null && endDate.isBefore(now)) {
      return;
    }

    for (final (index, time) in _extractTimes(medication.timesList).indexed) {
      final scheduled = _nextTimeFor(time.hour, time.minute, startDate);
      if (scheduled == null) {
        continue;
      }

      await _plugin.zonedSchedule(
        _notificationIdFor(medicationId, index),
        'Medication reminder',
        'Time to take ${medication.name} (${medication.dosage}).',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication_reminder',
      );
    }
  }

  Iterable<_HourMinute> _extractTimes(String timesList) sync* {
    final parts = timesList.split(',');
    for (final raw in parts) {
      final value = raw.trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
      if (match == null) continue;

      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour == null || minute == null) continue;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;

      yield _HourMinute(hour, minute);
    }
  }

  tz.TZDateTime? _nextTimeFor(int hour, int minute, DateTime? startDate) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final normalizedStart = startDate == null
        ? null
        : tz.TZDateTime(
            tz.local,
            startDate.year,
            startDate.month,
            startDate.day,
            hour,
            minute,
          );

    if (normalizedStart != null && scheduled.isBefore(normalizedStart)) {
      scheduled = normalizedStart;
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  int _notificationIdFor(int medicationId, int timeIndex) {
    return (medicationId * 100) + timeIndex;
  }
}

class _HourMinute {
  const _HourMinute(this.hour, this.minute);

  final int hour;
  final int minute;
}
