import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_dashboard_screen.dart';
import 'home_screen.dart';
import '../features/workspace/presentation/workspace_screen.dart';
import 'you_screen.dart';

/// Authenticated shell — Home / Chat / Spaces / You
/// Minimal, premium, no duplicate nav. Preserves tab state via IndexedStack.
class AppShell extends StatefulWidget {
  final String? initialPrompt;
  final int initialTab;
  const AppShell({super.key, this.initialPrompt, this.initialTab = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialTab.clamp(0, 3);
  String? _chatPrompt;

  static const _bg = Color(0xFF080808);

  @override
  void initState() {
    super.initState();
    _chatPrompt = widget.initialPrompt;
    if (_chatPrompt != null && _chatPrompt!.trim().isNotEmpty) {
      _index = 1; // open Chat when coming from FirstRun
    }
  }

  void _tap(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    // clear chat prompt when leaving chat so it doesn't re-trigger
    if (i != 1) _chatPrompt = null;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFFAF8F4) : _bg;

    final tabs = <Widget>[
      HomeDashboardScreen(
        hideNavigation: true,
        onStartChat: (p) => setState(() { _chatPrompt = p; _index = 1; }),
      ),
      BanataqHome(key: ValueKey('chat-${_chatPrompt ?? 'no-prompt'}'), initialPrompt: _chatPrompt),
      const WorkspaceScreen(),
      const YouScreen(),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        backgroundColor: bg,
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border(top: BorderSide(color: isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.07))),
            ),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                _Item(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', selected: _index == 0, onTap: () => _tap(0), isLight: isLight),
                _Item(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Chat', selected: _index == 1, onTap: () => _tap(1), isLight: isLight),
                _Item(icon: Icons.workspaces_outlined, activeIcon: Icons.workspaces_rounded, label: 'Spaces', selected: _index == 2, onTap: () => _tap(2), isLight: isLight),
                _Item(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'You', selected: _index == 3, onTap: () => _tap(3), isLight: isLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon; final IconData activeIcon; final String label; final bool selected; final VoidCallback onTap; final bool isLight;
  const _Item({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap, required this.isLight});
  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFD4AF5A) : (isLight ? Colors.black.withValues(alpha: 0.42) : Colors.white.withValues(alpha: 0.52));
    return Expanded(
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0.2, color: color)),
          ]),
        ),
      ),
    );
  }
}
