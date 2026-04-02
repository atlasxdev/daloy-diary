import 'package:flutter/material.dart';

import 'today_screen.dart';
import 'calendar_screen.dart';
import 'log_screen.dart';
import 'settings_screen.dart';

/// The root navigation shell — a bottom tab bar with 4 tabs.
///
/// HIG guidance:
///   - Use a tab bar for 3-5 top-level destinations
///   - Each tab preserves its own navigation state
///   - Selected tab uses the app's primary (accent) color
///   - Unselected tabs use a muted gray
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // Build screens lazily — each tab keeps its state while
  // the user switches between them.
  final _screens = const [
    TodayScreen(),
    CalendarScreen(),
    LogScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs alive so they don't rebuild
      // when you switch back. This matches iOS tab bar behavior.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // Thin top border — subtle separator like iOS.
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerTheme.color ??
                  Colors.grey.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined),
              activeIcon: Icon(Icons.today),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
