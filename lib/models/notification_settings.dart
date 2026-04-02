import 'package:hive/hive.dart';

part 'notification_settings.g.dart';

/// Stores the user's notification preferences.
///
/// This model maps directly to docs/notifications.md "User Controls":
///   - Enable/disable notifications
///   - Set reminder time
///   - Adjust pre-period alert days
///   - Turn off specific notification types
///
/// There is only ever ONE instance of this in the database
/// (it's the user's current settings, not a list of settings).
@HiveType(typeId: 4)
class NotificationSettings extends HiveObject {
  /// Master switch — turns ALL notifications on or off.
  @HiveField(0)
  bool notificationsEnabled;

  /// Whether to send daily reminders during period days.
  @HiveField(1)
  bool dailyRemindersEnabled;

  /// Whether to send pre-period alerts.
  @HiveField(2)
  bool prePeriodAlertsEnabled;

  /// What hour (0-23) to send daily period reminders.
  /// Stored as hour because Hive can't store TimeOfDay directly.
  @HiveField(3)
  int reminderHour;

  /// What minute (0-59) to send daily period reminders.
  @HiveField(4)
  int reminderMinute;

  /// What hour (0-23) to send pre-period alerts.
  @HiveField(5)
  int alertHour;

  /// What minute (0-59) to send pre-period alerts.
  @HiveField(6)
  int alertMinute;

  /// How many days before the predicted period to start alerting.
  /// Per docs/notifications.md, default is 3.
  @HiveField(7)
  int prePeriodAlertDays;

  NotificationSettings({
    this.notificationsEnabled = true,
    this.dailyRemindersEnabled = true,
    this.prePeriodAlertsEnabled = true,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.alertHour = 9,
    this.alertMinute = 0,
    this.prePeriodAlertDays = 3,
  });
}
