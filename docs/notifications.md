# Notification System Design

## Overview

Notifications are a core feature of the app. They must:

- Work offline.
- Trigger reliably.
- Be customizable by the user.

Current package:

- `flutter_local_notifications`

## Notification Types

### 1. Period Daily Reminders

**Purpose**
Remind users during active period days.

**Trigger condition**

- From Day 1 of the period start.
- Until Day 5 to Day 7, based on user configuration.

**Schedule**

- Once daily.
- Default time: 8:00 AM local time.

**Example messages**

- "Don’t forget to use a warm compress today 💛"
- "Take it easy today and check in with how you feel."

### 2. Pre-Period Alerts

**Purpose**
Notify the user before the predicted period start.

**Trigger condition**

- X days before the predicted period date.
- Default lead time: 3 days.

**Example messages**

- "Your period is expected in 3 days."
- "A new cycle may start soon. Prepare anything you need."

### 3. Optional Notifications

#### Fertility Window Alerts

- Notify the user when entering the predicted fertility window.

#### Logging Reminders

- Remind the user to log symptoms, mood, or flow for the day.

## Scheduling Logic

### Step 1: Calculate Next Period

```txt
average_cycle_length = average(last 3 to 6 cycles)
next_period_date = last_period_start + average_cycle_length
```

### Step 2: Schedule Notifications

#### Daily Period Notifications

```txt
for day in 0..period_length:
  schedule notification at user_defined_time
```

#### Pre-Period Notification

```txt
pre_period_date = next_period_date - reminder_days
schedule notification
```

## Rescheduling Rules

Notifications must be recalculated and rescheduled when:

- The user logs a new period.
- The user edits past cycle data.
- The user changes notification settings.
- The device timezone changes.

## User Controls

Users must be able to:

- Enable or disable all notifications.
- Set the daily reminder time.
- Adjust pre-period alert lead time.
- Turn specific notification types on or off.

## Edge Cases

- Irregular cycles: adjust predictions dynamically using recent cycle history.
- Missed logs: fall back to the last reliable cycle data.
- Timezone changes: cancel and reschedule notifications using the new local timezone.
- Permission revoked: surface a clear in-app prompt to re-enable notifications.
- Device restart: restore scheduled notifications automatically if required by platform behavior.

## Implementation Notes

- Always cancel old notifications before scheduling new ones.
- Use stable, unique notification IDs for each notification type and date.
- Keep message tone supportive and non-intrusive.
- Avoid duplicate notifications for the same event.
- Store enough local data to rebuild schedules offline.

## Testing Checklist

- [ ] Notifications trigger while the app is closed.
- [ ] Notifications persist after device restart.
- [ ] User-selected reminder times are respected.
- [ ] Rescheduling works after period logs are updated.
- [ ] Timezone changes reschedule notifications correctly.
- [ ] Disabled notification types do not fire.
- [ ] Offline scheduling still works correctly.
