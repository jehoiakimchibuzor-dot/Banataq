import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../intelligence/application/intelligence_engine.dart';
import '../../intelligence/application/workspace_knowledge_adapter.dart';
import '../data/repositories/workspace_repository.dart';
import '../domain/models/workspace_session.dart';
import '../services/workspace_service.dart';
import '../widgets/workspace_header_sliver.dart';
import 'session_detail_screen.dart';
import 'tabs/files_tab.dart';
import 'tabs/memory_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/sessions_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/timeline_tab.dart';
import 'workspace_controller.dart';
import 'workspace_search_screen.dart';

/// Full workspace screen: collapsible cover header + six pinned tabs
/// (Overview, Sessions, Files, Tasks, Timeline, Memory).
///
/// Uses a [NestedScrollView] so the header collapses and the tab bar sticks
/// while any inner tab scrolls. Every tab is live from [WorkspaceController].
class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, this.controller});

  /// Inject a controller (tests) or leave null to resolve one from DI.
  final WorkspaceController? controller;

  static const routeName = '/workspace';

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final WorkspaceController _controller;
  late final bool _ownsController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Self-contained by default: the shell owns a mock-backed controller so
    // the screen renders without DI/Firebase (previews, route, tests). Sprint 2
    // passes a Firestore-backed controller here instead.
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        WorkspaceController(
          repository: MockWorkspaceRepository(
            // Runtime uses an empty workspace (no seeded GANO data); tests
            // inject their own seeded fixture.
            service: MockWorkspaceService(seed: false),
          ),
        );
    _controller.onNotice = (message) {
      if (mounted) AppSnackbar.show(context, message);
    };
    _controller.onOpenSession = _openSession;
    _controller.onSeeAllSessions = () => _tabController.animateTo(1);
    _controller.onSeeAllFiles = () => _tabController.animateTo(2);
    _controller.onSeeAllTasks = () => _tabController.animateTo(3);
    _controller.onSeeAllMemory = () => _tabController.animateTo(5);
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).maybePop();

  Future<void> _openSession(WorkspaceSession session) async {
    // Build the Ollama-backed brain. Building never touches the network (the
    // adapter connects lazily on the first chat), so a failure here only means
    // the session falls back to the legacy mock stack.
    IntelligenceEngine? engine;
    try {
      engine = await WorkspaceBrainFactory.buildWithOllama(
        repository: _controller.repository,
      );
    } catch (_) {
      engine = null;
    }
    if (!mounted) return;
    await AppPageTransitions.pushFade(
      context,
      SessionDetailScreen(
        repository: _controller.repository,
        sessionId: session.id,
        engine: engine,
      ),
    );
    if (mounted) _controller.refresh();
  }

  void _continueWorking() {
    final active = _controller.sessions
        .where((s) => s.status == SessionStatus.inProgress)
        .toList();
    if (active.isNotEmpty) {
      _openSession(active.first);
    } else {
      _controller.showPlaceholder('Continue');
    }
  }

  Future<void> _openSearch() async {
    await AppPageTransitions.pushFade(
      context,
      WorkspaceSearchScreen(controller: _controller),
    );
    if (mounted) _controller.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final workspace = _controller.workspace;
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              WorkspaceHeaderSliver(
                workspace: workspace,
                onBack: _back,
                onContinue: _continueWorking,
                onTogglePin: _controller.togglePin,
                onToggleFavourite: _controller.toggleFavourite,
                onSettings: () => _controller.showPlaceholder('Workspace settings'),
                onSearch: _openSearch,
              ),
              _TabBarSliver(
                child: AppTabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Home'),
                    Tab(text: 'Chats'),
                    Tab(text: 'Files'),
                    Tab(text: 'Tasks'),
                    Tab(text: 'Timeline'),
                    Tab(text: 'Memory'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(controller: _controller, workspace: workspace),
                SessionsTab(controller: _controller),
                FilesTab(controller: _controller),
                TasksTab(controller: _controller),
                TimelineTab(controller: _controller),
                MemoryTab(controller: _controller),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pinned, fixed-height sliver that hosts the tab bar so it stays on screen
/// while tabs scroll underneath.
class _TabBarSliver extends StatelessWidget {
  const _TabBarSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FixedExtentDelegate(
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FixedExtentDelegate extends SliverPersistentHeaderDelegate {
  _FixedExtentDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _FixedExtentDelegate oldDelegate) =>
      oldDelegate.child != child;
}
