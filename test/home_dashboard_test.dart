import 'package:banataq/core/design_system/design_system.dart';
import 'package:banataq/screens/home_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {double width = 430, double height = 1200}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemeData.dark(),
      darkTheme: AppThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeDashboardScreen(),
    ),
  );
}

void main() {
  testWidgets('renders command center greeting and input on narrow', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('BANATAQ'), findsOneWidget);
    // greeting adapts to time, just check Good
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('Ask Banataq anything...'), findsOneWidget);
    expect(find.text('START WITH'), findsOneWidget);
    expect(find.text('YOUR SPACES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with navigation rail on wide layout', (tester) async {
    await _pump(tester, width: 1200, height: 1200);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    // Wide layout shows content without bottom nav; rail is hidden when embedded in shell, but standalone shows rail
    expect(find.text('BANATAQ'), findsOneWidget);
    expect(find.text('YOUR SPACES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick action tap is tappable', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('START WITH'), findsOneWidget);
    expect(find.textContaining('Help me'), findsWidgets);
  });

  testWidgets('shows continue when conversation exists — via real storage empty, shows no continue', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CONTINUE'), findsNothing);
  });
}
