import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// NotificationService handles all local notification scheduling.
///
/// How it works at a high level:
///   1. We initialize the notification plugin once at app start.
///   2. When the user logs a period, we calculate the next predicted period.
///   3. We schedule two types of notifications:
///      - "Daily reminders" during active period days
///      - "Pre-period alerts" a few days before the next predicted period
///   4. When cycle data changes, we cancel old notifications and reschedule.
class NotificationService {
  // This is the main plugin instance — it talks to Android/iOS for us.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification ID ranges ──────────────────────────────────
  // We use unique IDs so we can cancel specific notifications later.
  // Daily reminders use IDs 1000-1006 (one per day, up to 7 days).
  // Pre-period alerts use IDs 2000-2002 (up to 3 days before).
  static const int _dailyReminderBaseId = 1000;
  static const int _prePeriodBaseId = 2000;

  /// Call this once when the app starts.
  ///
  /// It sets up the notification plugin with platform-specific settings
  /// (icon for Android, permissions for iOS).
  static Future<void> init() async {
    // Initialize timezone data — needed because we schedule notifications
    // at specific local times (e.g. "8:00 AM in the user's timezone").
    tz_data.initializeTimeZones();

    // Android settings: the icon that shows in the notification bar.
    // '@mipmap/ic_launcher' is the default app icon Flutter generates.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings: request permission to show alerts, play sounds, etc.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // On Android 13+ (API 33), we must request POST_NOTIFICATIONS at runtime.
    // Without this, notifications are silently blocked.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Send a notification immediately — for testing purposes only.
  /// Call this to verify that notifications show up on the device.
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daloy_diary_channel',
      'Daloy Diary Notifications',
      channelDescription: 'Period reminders and pre-period alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      9999, // Unique ID for test notification.
      'Daloy Diary — Test',
      'Notifications are working!',
      notificationDetails,
    );
  }

  // ── Scheduling daily period reminders ────────────────────────

  /// Schedule a reminder for each day of an active/upcoming period.
  ///
  /// [periodStartDate] — the day the period starts (or started).
  /// [periodLengthDays] — how many days the period usually lasts (default: 5).
  /// [reminderTime] — what time of day to send the reminder (default: 8:00 AM).
  ///
  /// Per docs/notifications.md:
  ///   "From Day 1 of period start, until Day 5-7 (configurable)"
  ///   "Once daily, default: Morning (e.g., 8:00 AM)"
  static Future<void> scheduleDailyReminders({
    required DateTime periodStartDate,
    int periodLengthDays = 5,
    TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0),
  }) async {
    // First, cancel any previously scheduled daily reminders.
    // This follows the rule: "Always cancel old notifications before
    // scheduling new ones."
    await cancelDailyReminders();

    // Supportive messages to rotate through (one per day).
    const messages = [
      'Day 1 — Take it easy today 💛',
      'Day 2 — Stay hydrated and rest well.',
      'Day 3 — You\'re doing great, keep going!',
      'Day 4 — A warm compress can help with cramps.',
      'Day 5 — Almost there — be kind to yourself.',
      'Day 6 — Listen to your body today.',
      'Day 7 — Rest up, you\'ve got this!',
    ];

    for (int day = 0; day < periodLengthDays; day++) {
      final notificationDate = periodStartDate.add(Duration(days: day));
      final scheduledDateTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // Don't schedule notifications in the past.
      if (scheduledDateTime.isBefore(DateTime.now())) continue;

      final message = messages[day % messages.length];

      await _scheduleNotification(
        id: _dailyReminderBaseId + day,
        title: 'Daloy Diary — Period Reminder',
        body: message,
        scheduledDate: scheduledDateTime,
      );
    }
  }

  // ── Scheduling pre-period alerts ─────────────────────────────

  /// Schedule alerts before the predicted next period.
  ///
  /// [nextPeriodDate] — the predicted start date of the next period.
  /// [daysBefore] — how many days before to start alerting (default: 3).
  /// [alertTime] — what time to send the alert (default: 9:00 AM).
  ///
  /// Per docs/notifications.md:
  ///   "X days before predicted period (default: 3 days)"
  static Future<void> schedulePrePeriodAlerts({
    required DateTime nextPeriodDate,
    int daysBefore = 3,
    TimeOfDay alertTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    // Cancel any existing pre-period alerts first.
    await cancelPrePeriodAlerts();

    for (int i = daysBefore; i >= 1; i--) {
      final alertDate = nextPeriodDate.subtract(Duration(days: i));
      final scheduledDateTime = DateTime(
        alertDate.year,
        alertDate.month,
        alertDate.day,
        alertTime.hour,
        alertTime.minute,
      );

      // Don't schedule in the past.
      if (scheduledDateTime.isBefore(DateTime.now())) continue;

      await _scheduleNotification(
        id: _prePeriodBaseId + (daysBefore - i),
        title: 'Daloy Diary — Heads Up',
        body: 'Your period is expected in $i day${i > 1 ? 's' : ''}.',
        scheduledDate: scheduledDateTime,
      );
    }
  }

  // ── Cancellation ─────────────────────────────────────────────

  /// Cancel all daily period reminders.
  static Future<void> cancelDailyReminders() async {
    // Cancel IDs 1000 through 1006 (7 possible daily reminders).
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_dailyReminderBaseId + i);
    }
  }

  /// Cancel all pre-period alerts.
  static Future<void> cancelPrePeriodAlerts() async {
    // Cancel IDs 2000 through 2002 (up to 3 pre-period alerts).
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel(_prePeriodBaseId + i);
    }
  }

  /// Cancel every notification this app has scheduled.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Rescheduling (call when cycle data changes) ──────────────

  /// Reschedule all notifications based on updated cycle data.
  ///
  /// Per docs/notifications.md, notifications must be updated when:
  ///   - User logs a new period
  ///   - User edits past cycle data
  ///   - User changes notification settings
  ///
  /// [currentPeriodStart] — start of the current/latest period (if ongoing).
  /// [periodLength] — expected period length in days.
  /// [nextPeriodDate] — predicted start of the next period.
  /// [reminderTime] — time for daily reminders.
  /// [alertTime] — time for pre-period alerts.
  /// [daysBefore] — how many days before period to start alerting.
  static Future<void> rescheduleAll({
    DateTime? currentPeriodStart,
    required int periodLength,
    required DateTime nextPeriodDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0),
    TimeOfDay alertTime = const TimeOfDay(hour: 9, minute: 0),
    int daysBefore = 3,
  }) async {
    // Cancel everything first, then reschedule.
    await cancelAll();

    // If there's an ongoing period, schedule daily reminders for it.
    if (currentPeriodStart != null) {
      await scheduleDailyReminders(
        periodStartDate: currentPeriodStart,
        periodLengthDays: periodLength,
        reminderTime: reminderTime,
      );
    }

    // Always schedule pre-period alerts for the next predicted period.
    await schedulePrePeriodAlerts(
      nextPeriodDate: nextPeriodDate,
      daysBefore: daysBefore,
      alertTime: alertTime,
    );
  }

  // ── Private helper ───────────────────────────────────────────

  /// The actual platform call to schedule a single notification.
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Convert our DateTime to a timezone-aware TZDateTime.
    // This is required by the plugin for scheduled notifications.
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Android-specific display settings.
    const androidDetails = AndroidNotificationDetails(
      'daloy_diary_channel',          // channel ID (unique per app)
      'Daloy Diary Notifications',    // channel name (visible in phone settings)
      channelDescription: 'Period reminders and pre-period alerts',
      importance: Importance.high,    // shows as a banner on most phones
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
