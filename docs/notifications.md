# 🔔 Notification System Design

## 🧠 Overview

Notifications are a core feature of the app. They must:

- Work offline
- Trigger reliably
- Be customizable by the user

We use:

- `flutter_local_notifications`

---

## 📅 Notification Types

### 1. Period Daily Reminders

**Purpose:**
Remind users during active period days.

**Trigger Condition:**

- From Day 1 of period start
- Until Day 5–7 (configurable)

**Schedule:**

- Once daily
- Default: Morning (e.g., 8:00 AM)

**Example Message:**

- "Don’t forget to use a warm compress today 💛"

---

### 2. Pre-Period Alerts

**Purpose:**
Notify user before expected period start.

**Trigger Condition:**

- X days before predicted period (default: 3 days)

**Example Message:**

- "Your period is expected in 3 days"

---

### 3. Optional Notifications (Future)

#### Fertility Window Alerts

- Notify when entering fertile window

#### Logging Reminders

- "Don’t forget to log today’s symptoms"

---

## ⚙️ Scheduling Logic

### Step 1: Calculate Next Period

```
average_cycle_length = average(last 3–6 cycles)

next_period_date = last_period_start + average_cycle_length
```

---

### Step 2: Schedule Notifications

#### Daily Period Notifications

```
for day in 0..period_length:
  schedule notification at user_defined_time
```

---

#### Pre-Period Notification

```
pre_period_date = next_period_date - reminder_days

schedule notification
```

---

## 🔄 Rescheduling Rules

Notifications must be updated when:

- User logs a new period
- User edits past cycle data
- User changes notification settings

---

## 👤 User Controls

Allow users to:

- Enable/disable notifications
- Set reminder time
- Adjust pre-period alert days
- Turn off specific notification types

---

## ⚠️ Edge Cases

- Irregular cycles → adjust predictions dynamically
- Missed logs → fallback to last known cycle
- Timezone changes → reschedule notifications

---

## 🧪 Testing Checklist

- [ ] Notifications trigger when app is closed
- [ ] Notifications persist after device restart
- [ ] Time settings are respected
- [ ] Rescheduling works correctly

---

## 💡 Notes

- Always cancel old notifications before scheduling new ones
- Use unique IDs for each notification type
- Keep messages supportive and non-intrusive
