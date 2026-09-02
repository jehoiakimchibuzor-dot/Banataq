import 'package:flutter/material.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/theme_studio_screen.dart';
import '../screens/saved_answers_screen.dart';
import '../features/workspace/presentation/workspace_screen.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  void _coming(BuildContext c, String label) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$label — coming soon'), duration: const Duration(milliseconds: 1400)));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFFAF8F4) : const Color(0xFF080808);
    final primary = isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0);
    final muted = isLight ? const Color(0xFF6B6B6B) : const Color(0xFF9A9A9A);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        title: Text('You', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: primary)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Section(label: 'PROFILE', primary: primary, muted: muted, isLight: isLight, children: [
            _Row(title: 'Profile', subtitle: 'Name, avatar, account', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          ]),
          _Section(label: 'YOUR STUFF', primary: primary, muted: muted, isLight: isLight, children: [
            _Row(title: 'Saved answers', subtitle: 'Your kept responses', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedAnswersScreen()))),
            _Row(title: 'Your files', subtitle: 'Uploads and documents', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkspaceScreen()))),
          ]),
          _Section(label: 'BANATAQ', primary: primary, muted: muted, isLight: isLight, children: [
            _Row(title: 'AI models', subtitle: 'Manage providers and models', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            _Row(title: 'Personalization', subtitle: 'Goals and assistance style', onTap: () => _coming(context, 'Personalization')),
          ]),
          _Section(label: 'APP', primary: primary, muted: muted, isLight: isLight, children: [
            _Row(title: 'Theme', subtitle: 'Make BANATAQ yours — Royal Blue, Gold, Green…', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeStudioScreen()))),
            _Row(title: 'Appearance', subtitle: 'Light / dark / system', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeStudioScreen()))),
            _Row(title: 'Language', subtitle: 'App language', onTap: () => _coming(context, 'Language')),
            _Row(title: 'Data & privacy', subtitle: 'Export and delete', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            _Row(title: 'About Banataq', subtitle: 'Born in Africa. Built for the world.', onTap: () => _coming(context, 'About Banataq')),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label; final List<Widget> children; final Color primary; final Color muted; final bool isLight;
  const _Section({required this.label, required this.children, required this.primary, required this.muted, required this.isLight});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 8), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: const Color(0xFFD4AF5A).withValues(alpha: 0.95)))),
        Container(
          decoration: BoxDecoration(color: isLight ? Colors.white : const Color(0xFF121212), borderRadius: BorderRadius.circular(16), border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.07))),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) Divider(height: 1, thickness: 1, color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String title; final String? subtitle; final VoidCallback onTap;
  const _Row({required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0))),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 12.5, color: isLight ? const Color(0xFF6B6B6B) : Colors.white.withValues(alpha: 0.55)))],
          ])),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: isLight ? Colors.black.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.28)),
        ]),
      ),
    );
  }
}
