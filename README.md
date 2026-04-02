# 🩸 Daloy Diary – Menstrual Cycle Tracker

## 📱 Overview

Daloy Diary is a privacy-first mobile application built with Flutter that helps users track menstrual cycles, log sexual activity, and receive personalized health reminders.

The app focuses on:

- Simplicity
- Offline-first functionality
- Reliable local notifications
- User privacy

---

## 🚀 Features

### Core

- Track menstrual cycle (start and end dates)
- Log sexual activity with protection type (protected/unprotected) and optional notes
- Predict next period based on previous cycles
- Light and dark theme support

### Notifications

- Daily reminders during period days
- Pre-period alerts (before expected start date)

### Additional

- Symptom tracking (cramps, fatigue, etc.)
- Mood tracking
- Calendar-based cycle visualization with color-coded indicators
- Today dashboard with cycle phase, stats, and daily logs

---

## 🧱 Tech Stack

- **Frontend:** Flutter
- **Local Database:** Hive
- **Notifications:** flutter_local_notifications
- **Optional Backend:** Supabase / Firebase

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK installed
- Android Studio / VS Code
- Android Emulator or Physical Device

---

### Installation

```bash
git clone <your-repo-url>
cd Daloy Diary
flutter pub get
```

---

### Run the App

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
  core/           # Theme, shared constants
  features/       # Feature-specific logic (cycle, logs, notifications)
  models/         # Hive data models (Period, Cycle, LogEntry, SexualActivityLog, NotificationSettings)
  screens/        # UI screens (Today, Calendar, Log, LogEntry, Settings, AppShell)
  services/       # Storage, notifications, cycle prediction
```

---

## 🔒 Privacy

- All data is stored locally by default
- No data is shared externally without user consent
- Future cloud sync is optional

---

## 🧭 Roadmap

### MVP

- [x] Period tracking
- [x] Prediction logic
- [x] Local notifications
- [x] Calendar UI
- [x] Symptom and mood logging
- [x] Sexual activity logging (protection type + notes)
- [x] Light/dark theme

### V2

- [ ] Cloud sync
- [ ] Partner sharing
- [ ] Advanced analytics
- [ ] Privacy lock (PIN / biometric)

---

## 👨‍💻 Developer Notes

- Keep UI minimal and fast
- Prioritize offline functionality
- Avoid overcomplicating prediction logic early
