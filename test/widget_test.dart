import 'package:banataq/features/auth/domain/entities/auth_user.dart';
import 'package:banataq/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_dependencies.dart';

void main() {
  testWidgets('Banataq shows the sign-in screen when signed out', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'personalization_complete': true,
      'first_run_complete': true,
    });
    await initTestDependencies(currentUser: null);

    await tester.pumpWidget(const BanataqApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('MEET BANATAQ'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Personalization is now after auth, so unauthenticated lands on login.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue with Banataq'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('Banataq home loads for an authenticated user', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'personalization_complete': true,
      'first_run_complete': true,
    });
    await initTestDependencies(
      currentUser: const AuthUser(
        uid: 'test-uid',
        email: 'test@banataq.app',
        displayName: 'Test User',
      ),
    );

    await tester.pumpWidget(const BanataqApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
  });

  testWidgets('first run shows onboarding and Skip reaches sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initTestDependencies(currentUser: null);

    await tester.pumpWidget(const BanataqApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('MEET BANATAQ'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('authenticated without personalization shows personalization', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'personalization_complete': false,
      'first_run_complete': false,
    });
    await initTestDependencies(
      currentUser: const AuthUser(uid: 'test-uid', email: 'test@banataq.app', displayName: 'Test User'),
    );
    await tester.pumpWidget(const BanataqApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    expect(find.textContaining('What are you here'), findsOneWidget);
  });
}
