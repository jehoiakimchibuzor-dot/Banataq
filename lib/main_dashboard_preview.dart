import 'package:flutter/material.dart';
import 'core/design_system/design_system.dart';
import 'screens/home_dashboard_screen.dart';

/// Standalone preview for the Home Dashboard layout increment.
///
/// Run with: `flutter run -t lib/main_dashboard_preview.dart`
///
/// This deliberately bypasses auth, DI, Firebase and navigation so the
/// dashboard can be reviewed purely as UI with mock data.
void main() => runApp(const DashboardPreviewApp());

class DashboardPreviewApp extends StatelessWidget {
  const DashboardPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banataq · Home Dashboard',
      theme: AppThemeData.dark(),
      darkTheme: AppThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeDashboardScreen(),
    );
  }
}
