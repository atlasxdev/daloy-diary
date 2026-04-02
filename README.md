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
- Log sexual activity with optional notes
- Predict next period based on previous cycles

### Notifications

- Daily reminders during period days
- Pre-period alerts (before expected start date)

### Additional

- Symptom tracking (cramps, fatigue, etc.)
- Mood tracking
- Calendar-based cycle visualization
- Privacy lock (PIN / biometric)

---

## 🧱 Tech Stack

- **Frontend:** Flutter
- **Local Database:** Hive or SQLite
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

## 📁 Project Structure (Suggested)

```
lib/
  core/
  features/
    cycle/
    logs/
    notifications/
  services/
  models/
  screens/
```

---

## 🔒 Privacy

- All data is stored locally by default
- No data is shared externally without user consent
- Future cloud sync is optional

---

## 🧭 Roadmap

### MVP

- [ ] Period tracking
- [ ] Prediction logic
- [ ] Local notifications
- [ ] Calendar UI

### V2

- [ ] Cloud sync
- [ ] Partner sharing
- [ ] Advanced analytics

---

## 👨‍💻 Developer Notes

- Keep UI minimal and fast
- Prioritize offline functionality
- Avoid overcomplicating prediction logic early
