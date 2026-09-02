import 'package:banataq/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) {
    return MaterialApp(
      theme: AppThemeData.dark(),
      darkTheme: AppThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  test('AppThemeData exposes all theme extensions', () {
    final dark = AppThemeData.dark();
    final light = AppThemeData.light();

    for (final theme in [dark, light]) {
      expect(theme.extension<AppSpacingTheme>(), isNotNull);
      expect(theme.extension<AppRadiusTheme>(), isNotNull);
      expect(theme.extension<AppDurationsTheme>(), isNotNull);
      expect(theme.extension<AppMotionTheme>(), isNotNull);
      expect(theme.extension<AppElevationTheme>(), isNotNull);
      expect(theme.extension<AppShadowsTheme>(), isNotNull);
      expect(theme.extension<AppSemanticColors>(), isNotNull);
    }
  });

  testWidgets('core components render in dark theme', (tester) async {
    await tester.pumpWidget(wrap(Column(
      children: [
        AppButton(label: 'Primary', onPressed: () {}),
        AppButton(label: 'Loading', onPressed: () {}, isLoading: true),
        const AppCard(
          child: Text('card'),
        ),
        const AppBadge(label: 'Badge'),
        const SuccessBadge(label: 'Done', dot: true),
        const AiBadge(label: 'AI'),
        const AppChip(label: 'Chip'),
        const AppCategoryChip(label: 'Category', icon: Icons.tag_rounded),
        const AppTag(label: 'Tag'),
        const AppEmptyState(title: 'Nothing here', description: 'All clear.'),
        const AppDivider(),
      ],
    )));

    expect(find.text('Primary'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is ProgressIndicator), findsOneWidget);
    expect(find.text('card'), findsOneWidget);
    expect(find.text('Badge'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Chip'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('cards render with correct data', (tester) async {
    await tester.pumpWidget(wrap(Column(
      children: [
        WorkspaceCard(
          title: 'GANO',
          subtitle: 'Launch project',
          summary: 'Comparing suppliers',
          progressLabel: '3 of 6',
          progress: 0.5,
          onTap: () {},
        ),
        const FileCard(name: 'notes.pdf', type: AppFileType.pdf, summarized: true),
        const MemoryCard(title: 'Goal', content: 'Finish by Friday', source: 'Session Aug 1'),
        SuggestionCard(title: 'Draft the plan', onApply: () {}, onDismiss: () {}),
        const StatisticsCard(value: '12', label: 'Files'),
        InsightCard(title: 'Trend', description: 'You are moving fast.', onDismiss: () {}),
      ],
    )));

    expect(find.text('GANO'), findsOneWidget);
    expect(find.text('notes.pdf'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Draft the plan'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);
  });
}
