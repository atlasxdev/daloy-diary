import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/app_shell.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init();
  runApp(const DaloyDiaryApp());
}

/// A ValueNotifier that holds the current ThemeMode.
/// Settings screen writes to this, MaterialApp listens to it.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class DaloyDiaryApp extends StatefulWidget {
  const DaloyDiaryApp({super.key});

  @override
  State<DaloyDiaryApp> createState() => _DaloyDiaryAppState();
}

class _DaloyDiaryAppState extends State<DaloyDiaryApp> {
  @override
  void initState() {
    super.initState();
    // Load the saved theme preference on startup.
    final saved = StorageService().getThemeMode();
    themeNotifier.value = _parseThemeMode(saved);
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daloy Diary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeNotifier.value,
      home: const AppShell(),
    );
  }
}
