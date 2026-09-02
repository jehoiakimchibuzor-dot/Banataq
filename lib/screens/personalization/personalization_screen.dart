import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/onboarding_preferences.dart';
import '../../services/storage_service.dart';

/// Signature Banataq personalization: intent + assistance style + reveal.
/// See spec: onboarding → personalization (goals → style → ready) → auth.
class PersonalizationScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const PersonalizationScreen({
    super.key,
    required this.storage,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen>
    with TickerProviderStateMixin {
  int _page = 0; // 0 goals, 1 style, 2 ready
  final Set<String> _goals = {};
  final Set<String> _styles = {};
  late final AnimationController _fade;

  static const _bg = Color(0xFF080808);
  static const _surface = Color(0xFF121212);
  static const _gold = Color(0xFFD4AF5A);
  static const _warmWhite = Color(0xFFF8F6F0);

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
    _load();
  }

  Future<void> _load() async {
    final p = await widget.storage.loadOnboardingPreferences();
    if (p != null && mounted) setState(() { _goals.addAll(p.goals); _styles.addAll(p.assistanceStyles); });
  }

  Future<void> _persist() async {
    await widget.storage.saveOnboardingPreferences(
      OnboardingPreferences(goals: _goals, assistanceStyles: _styles),
    );
  }

  void _go(int i) {
    setState(() => _page = i);
    _fade.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    await _persist();
    await widget.storage.setPersonalizationComplete(value: true);
    if (!mounted) return;
    widget.onComplete();
  }

  Future<void> _skip() async {
    // Persist whatever was chosen (maybe empty) and mark done so we don't loop.
    if (_goals.isNotEmpty || _styles.isNotEmpty) await _persist();
    await widget.storage.setPersonalizationComplete(value: true);
    if (!mounted) return;
    widget.onSkip();
  }

  @override
  void dispose() { _fade.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bg : const Color(0xFFFAF8F4);
    final textPrimary = isDark ? _warmWhite : const Color(0xFF111111);
    final textSecondary = isDark ? const Color(0xFF9A9A9A) : const Color(0xFF6B6B6B);
    final surface = isDark ? _surface : Colors.white;
    final muted = isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Subtle depth: radial gold haze + vertical vignette.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.7),
                  radius: 1.1,
                  colors: [
                    _gold.withValues(alpha: isDark ? 0.08 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: isDark ? 0.22 : 0.06)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                  child: Row(
                    children: [
                      Text('BANATAQ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2.8, color: textPrimary.withValues(alpha: 0.88))),
                      const Spacer(),
                      if (_page < 2)
                        GestureDetector(
                          onTap: _skip,
                          child: Text('Skip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0,0.03), end: Offset.zero).animate(a), child: c)),
                    child: _buildPage(isDark, textPrimary, textSecondary, surface, muted),
                  ),
                ),
              ],
            ),
          ),
          // Back affordance (page 1,2)
          if (_page > 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 44, 0, 0),
                child: IconButton(
                  onPressed: () => _go(_page - 1),
                  icon: Icon(Icons.arrow_back, size: 20, color: muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(bool isDark, Color textPrimary, Color textSecondary, Color surface, Color muted) {
    if (_page == 0) return _goalsPage(isDark, textPrimary, textSecondary, surface);
    if (_page == 1) return _stylePage(isDark, textPrimary, textSecondary, surface);
    return _readyPage(isDark, textPrimary, textSecondary, surface);
  }

  // ── Goals ─────────────────────────────────────────────────────────────
  Widget _goalsPage(bool isDark, Color textPrimary, Color textSecondary, Color surface) {
    String micro;
    if (_goals.isEmpty) {
      micro = 'Pick whatever feels useful. Banataq will adapt.';
    } else if (_goals.length == 1) {
      micro = 'Good. Choose anything else you want Banataq to help with.';
    } else {
      micro = 'That gives Banataq a good starting point.';
    }

    final goals = <Map<String,String>>[
      {'id':'learn','title':'I want to learn','sub':'Understand \u2022 Practice \u2022 Improve','icon':'learn'},
      {'id':'getThingsDone','title':'I want to get things done','sub':'Work \u2022 Organize \u2022 Plan','icon':'work'},
      {'id':'build','title':'I want to build','sub':'Sell \u2022 Serve \u2022 Grow','icon':'build'},
      {'id':'create','title':'I want to create','sub':'Ideas \u2022 Content \u2022 Stories','icon':'create'},
      {'id':'communicate','title':'I want to communicate','sub':'Write \u2022 Translate \u2022 Connect','icon':'communicate'},
      {'id':'figureThingsOut','title':'I need to figure something out','sub':'Ask \u2022 Understand \u2022 Solve','icon':'figure'},
    ];

    IconData iconFor(String k) => switch(k){
      'learn' => Icons.school_outlined,
      'work' => Icons.task_alt_outlined,
      'build' => Icons.storefront_outlined,
      'create' => Icons.palette_outlined,
      'communicate' => Icons.chat_bubble_outline,
      _ => Icons.lightbulb_outline,
    };

    return FadeTransition(
      opacity: _fade,
      child: LayoutBuilder(builder: (context, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Text('LET\u2019S MAKE IT YOURS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.7, color: _gold.withValues(alpha: 0.92))),
              const SizedBox(height: 12),
              Text('What are you here\nto accomplish?', style: TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 12),
              AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: Text(micro, key: ValueKey(micro), style: TextStyle(fontSize: 13.5, height: 1.45, color: textSecondary))),
              const SizedBox(height: 22),
              // Vertical constellation — staggered with padding offsets for editorial rhythm.
              ...List.generate(goals.length, (i) {
                final g = goals[i];
                final id = g['id']!;
                final sel = _goals.contains(id);
                final offset = (i % 2 == 1) ? 10.0 : 0.0; // every other slightly indented
                return Padding(
                  padding: EdgeInsets.only(left: offset, bottom: 12),
                  child: _GoalCard(
                    title: g['title']!, sub: g['sub']!, icon: iconFor(g['icon']!),
                    selected: sel, surface: surface, isDark: isDark,
                    onTap: () {
                      setState(() { if (sel) { _goals.remove(id); } else { _goals.add(id); } });
                      HapticFeedback.selectionClick();
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
              Text(_goals.isEmpty ? 'Choose at least one' : 'Banataq will start here.', style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _goals.isEmpty ? _gold.withValues(alpha: 0.45) : _gold, foregroundColor: const Color(0xFF1A1200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  onPressed: () async {
                    if (_goals.isEmpty) return;
                    await _persist();
                    _go(1);
                  },
                  child: Text(_goals.isEmpty ? 'Choose what matters \u2192' : 'Continue \u2192'),
                ),
              ),
              const SizedBox(height: 10),
              Center(child: Text('You can change this anytime.', style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.85)))),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      }),
    );
  }

  // ── Style ─────────────────────────────────────────────────────────────
  Widget _stylePage(bool isDark, Color textPrimary, Color textSecondary, Color surface) {
    final opts = <Map<String,String>>[
      {'id':'simple','title':'Keep it simple','sub':'Explain things clearly and without unnecessary complexity.'},
      {'id':'direct','title':'Get straight to the point','sub':'Give me practical answers without the long journey.'},
      {'id':'thinkTogether','title':'Help me think','sub':'Explore the problem with me before jumping to an answer.'},
      {'id':'creative','title':'Help me create','sub':'Bring ideas, alternatives, and possibilities.'},
      {'id':'stepByStep','title':'Walk me through it','sub':'Break difficult things into clear steps.'},
    ];
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text('YOUR PREFERENCES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.7, color: _gold.withValues(alpha: 0.92))),
            const SizedBox(height: 12),
            Text('How should\nBanataq help you?', style: TextStyle(fontSize: 32, height: 1.05, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 10),
            Text('There is no right way. Choose what feels like you.', style: TextStyle(fontSize: 13.5, height: 1.45, color: textSecondary)),
            const SizedBox(height: 22),
            ...opts.map((o) {
              final sel = _styles.contains(o['id']);
              return _StyleRow(title: o['title']!, sub: o['sub']!, selected: sel, textPrimary: textPrimary, textSecondary: textSecondary, onTap: () {
                final id = o['id']!;
                setState(() { if (sel) { _styles.remove(id); } else { _styles.add(id); } });
                HapticFeedback.selectionClick();
              });
            }),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _styles.isEmpty ? _gold.withValues(alpha: 0.45) : _gold, foregroundColor: const Color(0xFF1A1200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () async {
                  if (_styles.isEmpty) return;
                  await _persist();
                  _go(2);
                },
                child: Text(_styles.isEmpty ? 'Choose what feels like you \u2192' : 'Continue \u2192'),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('You can change this anytime.', style: TextStyle(fontSize: 11, color: textSecondary))),
          ],
        ),
      ),
    );
  }

  // ── Ready ─────────────────────────────────────────────────────────────
  Widget _readyPage(bool isDark, Color textPrimary, Color textSecondary, Color surface) {
    String labelForGoal(String id) => switch(id){
      'learn' => 'Learn', 'getThingsDone' => 'Get things done', 'build' => 'Build', 'create' => 'Create', 'communicate' => 'Communicate', _ => 'Figure things out'
    };
    String labelForStyle(String id) => switch(id){
      'simple' => 'Simple', 'direct' => 'Direct', 'thinkTogether' => 'Think together', 'creative' => 'Creative', 'stepByStep' => 'Step-by-step', _ => id
    };
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text('Banataq is ready.', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.05, color: textPrimary)),
            const SizedBox(height: 10),
            Text('Built around what matters to you.', style: TextStyle(fontSize: 13.5, color: textSecondary)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold.withValues(alpha: 0.22)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08), blurRadius: 18, offset: const Offset(0,8))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR BANATAQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: _gold)),
                  const SizedBox(height: 12),
                  if (_goals.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: _goals.map((g) => _pill(labelForGoal(g), true)).toList()),
                  if (_goals.isNotEmpty && _styles.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.12))),
                  if (_styles.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: _styles.map((s) => _pill(labelForStyle(s), false)).toList()),
                  if (_goals.isEmpty && _styles.isEmpty) Text('A clean start — we\u2019ll learn as you go.', style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Let\u2019s get something done.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: const Color(0xFF1A1200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: _finish,
                child: const Text('Continue to Banataq \u2192'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool isGoal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: isGoal ? _gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(999), border: Border.all(color: isGoal ? _gold.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.14))),
      child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isGoal ? _gold : _warmWhite.withValues(alpha: 0.92))),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title; final String sub; final IconData icon; final bool selected; final Color surface; final bool isDark; final VoidCallback onTap;
  const _GoalCard({required this.title, required this.sub, required this.icon, required this.selected, required this.surface, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translateByDouble(0, selected ? -1.0 : 0, 0, 1)..scaleByDouble(selected ? 1.015 : 1.0, selected ? 1.015 : 1.0, 1, 1),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: selected ? surface.withValues(alpha: 0.96) : surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? const Color(0xFFD4AF5A).withValues(alpha: 0.55) : Colors.white.withValues(alpha: isDark ? 0.09 : 0.16), width: selected ? 1.2 : 1),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0,6))] : [],
        ),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: selected ? const Color(0xFFD4AF5A).withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? const Color(0xFFD4AF5A).withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.08))), child: Icon(icon, size: 18, color: selected ? const Color(0xFFD4AF5A) : Colors.white.withValues(alpha: 0.72))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.15, color: selected ? const Color(0xFFF8F6F0) : const Color(0xFFF8F6F0).withValues(alpha: 0.92))),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: selected ? const Color(0xFFD4AF5A).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.55))),
            ])),
            const SizedBox(width: 10),
            AnimatedContainer(duration: const Duration(milliseconds: 200), width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? const Color(0xFFD4AF5A) : Colors.transparent, border: Border.all(color: selected ? const Color(0xFFD4AF5A) : Colors.white.withValues(alpha: 0.22))), child: selected ? const Icon(Icons.check, size: 14, color: Color(0xFF1A1200)) : null),
          ],
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String title; final String sub; final bool selected; final Color textPrimary; final Color textSecondary; final VoidCallback onTap;
  const _StyleRow({required this.title, required this.sub, required this.selected, required this.textPrimary, required this.textSecondary, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? const Color(0xFFD4AF5A).withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.10), width: selected ? 1.1 : 0.8))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.15, color: selected ? textPrimary : textPrimary.withValues(alpha: 0.92))),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12.5, height: 1.35, color: selected ? textSecondary.withValues(alpha: 0.92) : textSecondary)),
            ])),
            const SizedBox(width: 12),
            Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? const Color(0xFFD4AF5A) : Colors.white.withValues(alpha: 0.22)), color: selected ? const Color(0xFFD4AF5A) : Colors.transparent), child: selected ? const Icon(Icons.check, size: 12, color: Color(0xFF1A1200)) : null),
          ],
        ),
      ),
    );
  }
}
