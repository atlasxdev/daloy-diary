# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Daloy Diary is a privacy-first menstrual cycle tracker built with Flutter. It tracks periods, logs sexual activity (with protection type and notes), predicts next cycles, and sends local notifications. All data is stored locally using Hive (offline-first).

The app has a working scaffold with four tabs (Today, Calendar, Log, Settings). Architecture uses feature-based organization under `lib/` with `models/`, `screens/`, `services/`, and `core/`.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis
flutter analyze

# Build APK
flutter build apk
```

## Tech Decisions

- **Local storage:** Hive (implemented via `hive_flutter`)
- **Notifications:** `flutter_local_notifications` — must work offline and persist after device restart
- **Linting:** Uses `flutter_lints` (see `analysis_options.yaml`)
- **Dart SDK:** ^3.11.4
- **Target platforms:** Android, iOS, web, Windows, Linux, macOS

## Key Design Constraints

- **Offline-first:** All core features must work without network connectivity
- **Privacy:** No data shared externally without user consent; cloud sync is optional/future
- **Notification scheduling:** Notifications reschedule when users log new periods, edit cycle data, or change settings. Always cancel old notifications before scheduling new ones; use unique IDs per notification type.
- **Prediction logic:** `next_period_date = last_period_start + average(last 3-6 cycles)`. Keep it simple early on.

## Documentation

- [docs/notifications.md](docs/notifications.md) — notification system design, scheduling logic, edge cases, and testing checklist
