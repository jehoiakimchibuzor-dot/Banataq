import 'package:banataq/core/design_system/design_system.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/presentation/workspace_controller.dart';
import 'package:banataq/features/workspace/presentation/workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(WorkspaceController controller) {
    return MaterialApp(
      theme: AppThemeData.dark(),
      home: WorkspaceScreen(controller: controller),
    );
  }

  WorkspaceController buildController() {
    final controller = WorkspaceController(repository: MockWorkspaceRepository());
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(buildController()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> switchTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('workspace screen renders header, tabs and overview', (tester) async {
    await pumpScreen(tester);

    expect(find.text('GANO'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Continue where you left off'), findsOneWidget);
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Memory'), findsWidgets);
  });

  test('toggleTask updates overview and workspace progress', () {
    final controller = buildController();
    final before = controller.overview.tasks.where((t) => t.done).length;
    final pending = controller.overview.tasks.firstWhere((t) => !t.done);

    controller.toggleTask(pending, true);

    final after = controller.overview.tasks.where((t) => t.done).length;
    expect(after, before + 1);
    expect(
      controller.workspace.progress,
      closeTo(after / controller.overview.tasks.length, 0.001),
    );
  });

  testWidgets('files tab shows seeded files and supports search', (tester) async {
    await pumpScreen(tester);
    await switchTab(tester, 'Files');

    expect(find.text('suppliers_quote.xlsx'), findsOneWidget);
    expect(find.text('gana_pitch_deck.pdf'), findsOneWidget);

    await tester.enterText(
      find.byType(AppSearchField).first,
      'pitch',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('gana_pitch_deck.pdf'), findsOneWidget);
    expect(find.text('suppliers_quote.xlsx'), findsNothing);
  });

  testWidgets('memory tab shows seeded memories', (tester) async {
    await pumpScreen(tester);
    await switchTab(tester, 'Memory');

    expect(find.text('Preferred currency'), findsOneWidget);
    expect(find.text('Alhaji Musa approves orders'), findsOneWidget);
  });

  testWidgets('timeline tab groups activity', (tester) async {
    await pumpScreen(tester);
    await switchTab(tester, 'Timeline');

    expect(find.text('Today'), findsWidgets);
    expect(find.textContaining('activities'), findsWidgets);
  });

  testWidgets('search opens from header and filters sessions', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Search this workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Search everything in this workspace'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'budget');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('School budget draft'), findsWidgets);
    expect(find.textContaining('result'), findsWidgets);
  });
}

