import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/onboarding_preferences.dart';

/// First real moment inside Banataq — shown once after auth + personalization.
/// Calm, premium, conversational. Not another onboarding page.
class FirstRunScreen extends StatefulWidget {
  final OnboardingPreferences preferences;
  final String displayName;
  final String? photoUrl;
  final ValueChanged<String> onStartChat;

  const FirstRunScreen({
    super.key,
    required this.preferences,
    required this.displayName,
    this.photoUrl,
    required this.onStartChat,
  });

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  final _inputCtrl = TextEditingController();
  final _focus = FocusNode();

  static const _bg = Color(0xFF080808);
  static const _gold = Color(0xFFD4AF5A);
  static const _warmWhite = Color(0xFFF8F6F0);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _inputCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _firstName {
    final n = widget.displayName.trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  String get _greeting {
    if (_firstName.isEmpty) return 'Hey there.';
    return 'Hey, $_firstName.';
  }

  String get _headline {
    final g = widget.preferences.goals;
    if (g.isEmpty) return 'What are we getting done today?';
    final hasMany = g.length >= 3;
    if (hasMany) return 'What are we getting done today?';
    if (g.contains('learn') && g.length == 1) return 'What are we learning today?';
    if (g.contains('build')) return 'What are we building today?';
    if (g.contains('create') && g.length == 1) return 'What are we creating today?';
    if (g.contains('communicate') && g.length == 1) return 'What are we working on?';
    if (g.contains('learn')) return 'What are we learning today?';
    if (g.contains('create')) return 'What are we creating today?';
    return 'What are we getting done today?';
  }

  List<_Suggestion> get _suggestions {
    const study = [
      _Suggestion(icon: Icons.menu_book_outlined, title: 'Explain a difficult topic', desc: 'Understand it clearly'),
      _Suggestion(icon: Icons.quiz_outlined, title: 'Quiz me on what I\'m learning', desc: 'Practice and improve'),
      _Suggestion(icon: Icons.summarize_outlined, title: 'Turn my notes into a summary', desc: 'Make it concise'),
    ];
    const business = [
      _Suggestion(icon: Icons.mail_outline, title: 'Help me write to a customer', desc: 'Clear and professional'),
      _Suggestion(icon: Icons.campaign_outlined, title: 'Create an advert for my business', desc: 'Sell with words'),
      _Suggestion(icon: Icons.map_outlined, title: 'Help me plan my next move', desc: 'Organize and decide'),
    ];
    const create = [
      _Suggestion(icon: Icons.lightbulb_outline, title: 'Give me ideas for my next post', desc: 'Fresh possibilities'),
      _Suggestion(icon: Icons.edit_outlined, title: 'Help me write this better', desc: 'Sharper and clearer'),
      _Suggestion(icon: Icons.auto_awesome_outlined, title: 'Turn this idea into something real', desc: 'From thought to thing'),
    ];
    const comm = [
      _Suggestion(icon: Icons.chat_bubble_outline, title: 'Help me write this message', desc: 'Say it right'),
      _Suggestion(icon: Icons.translate, title: 'Translate something for me', desc: 'Across languages'),
      _Suggestion(icon: Icons.workspace_premium_outlined, title: 'Make this sound more professional', desc: 'Polished tone'),
    ];
    const everyday = [
      _Suggestion(icon: Icons.help_outline, title: 'Help me understand something', desc: 'Simple and clear'),
      _Suggestion(icon: Icons.build_outlined, title: 'Help me solve a problem', desc: 'Step by step'),
      _Suggestion(icon: Icons.question_mark, title: 'Help me decide what to do', desc: 'Think it through'),
    ];

    final g = widget.preferences.goals;
    // Pick most relevant 3
    final pool = <_Suggestion>[];
    if (g.contains('learn')) pool.addAll(study);
    if (g.contains('build')) pool.addAll(business);
    if (g.contains('create')) pool.addAll(create);
    if (g.contains('communicate')) pool.addAll(comm);
    if (g.contains('getThingsDone')) pool.addAll(business);
    if (g.contains('figureThingsOut')) pool.addAll(everyday);
    if (pool.isEmpty) pool.addAll(everyday);
    // Deduplicate and take 3
    final seen = <String>{};
    final out = <_Suggestion>[];
    for (final s in pool) {
      if (seen.add(s.title) && out.length < 3) out.add(s);
    }
    // If still <3 (shouldn't happen), pad from everyday
    for (final s in everyday) {
      if (out.length >= 3) break;
      if (seen.add(s.title)) out.add(s);
    }
    return out.take(3).toList();
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    HapticFeedback.selectionClick();
    widget.onStartChat(t);
  }

  Widget _staggered(int index, Widget child) {
    final delay = 80 + index * 90;
    final anim = CurvedAnimation(parent: _entrance, curve: Interval(delay / 700, 1, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFFAF8F4) : _bg;
    final muted = isLight ? const Color(0xFF6B6B6B) : const Color(0xFF9A9A9A);
    final primary = isLight ? const Color(0xFF111111) : _warmWhite;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return Column(
              children: [
                // Top — BANATAQ + avatar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Text('BANATAQ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.6, color: primary.withValues(alpha: 0.88))),
                      const Spacer(),
                      if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                        CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.photoUrl!))
                      else
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.08), border: Border.all(color: _gold.withValues(alpha: 0.28))),
                          child: Center(child: Text((_firstName.isEmpty ? 'B' : _firstName[0].toUpperCase()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary))),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _staggered(0, Text('YOUR BANATAQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: _gold.withValues(alpha: 0.92)))),
                        const SizedBox(height: 14),
                        _staggered(1, Text(_greeting, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.2, color: muted))),
                        const SizedBox(height: 6),
                        _staggered(2, Text(_headline, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.06, letterSpacing: -0.4, color: primary))),
                        const SizedBox(height: 10),
                        _staggered(3, Text('Start anywhere. I\'ll help you figure out the rest.', style: TextStyle(fontSize: 14, height: 1.5, color: muted))),
                        const SizedBox(height: 26),
                        ...List.generate(_suggestions.length, (i) {
                          final s = _suggestions[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i == _suggestions.length - 1 ? 0 : 10),
                            child: _staggered(4 + i, _SuggestedRow(suggestion: s, isLight: isLight, onTap: () => _send(s.title))),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Brand line + input — keep accessible above keyboard
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    children: [
                      _staggered(7, Text('Study. Work. Create. Solve.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: muted.withValues(alpha: 0.85)))),
                      const SizedBox(height: 10),
                      _staggered(8, _FirstRunInput(controller: _inputCtrl, focusNode: _focus, isLight: isLight, onSend: _send)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Suggestion {
  final IconData icon; final String title; final String desc;
  const _Suggestion({required this.icon, required this.title, required this.desc});
}

class _SuggestedRow extends StatefulWidget {
  final _Suggestion suggestion; final bool isLight; final VoidCallback onTap;
  const _SuggestedRow({required this.suggestion, required this.isLight, required this.onTap});
  @override
  State<_SuggestedRow> createState() => _SuggestedRowState();
}
class _SuggestedRowState extends State<_SuggestedRow> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final surface = widget.isLight ? Colors.white : const Color(0xFF121212);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.99 : 1, _pressed ? 0.99 : 1, 1, 1),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFD4AF5A).withValues(alpha: widget.isLight ? 0.08 : 0.10) : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _pressed ? const Color(0xFFD4AF5A).withValues(alpha: 0.45) : (widget.isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08))),
          boxShadow: widget.isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0,4))] : [],
        ),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: widget.isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)), child: Icon(widget.suggestion.icon, size: 18, color: widget.isLight ? const Color(0xFF333333) : Colors.white.withValues(alpha: 0.78))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.suggestion.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2, color: widget.isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0))),
              const SizedBox(height: 2),
              Text(widget.suggestion.desc, style: TextStyle(fontSize: 12.5, height: 1.3, color: widget.isLight ? const Color(0xFF6B6B6B) : Colors.white.withValues(alpha: 0.55))),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 16, color: _pressed ? const Color(0xFFD4AF5A) : (widget.isLight ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.28))),
          ],
        ),
      ),
    );
  }
}

class _FirstRunInput extends StatefulWidget {
  final TextEditingController controller; final FocusNode focusNode; final bool isLight; final ValueChanged<String> onSend;
  const _FirstRunInput({required this.controller, required this.focusNode, required this.isLight, required this.onSend});
  @override
  State<_FirstRunInput> createState() => _FirstRunInputState();
}
class _FirstRunInputState extends State<_FirstRunInput> {
  @override
  void initState() { super.initState(); widget.controller.addListener(() => setState(() {})); }
  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final bg = widget.isLight ? Colors.white : const Color(0xFF181818);
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28), border: Border.all(color: hasText ? const Color(0xFFD4AF5A).withValues(alpha: 0.45) : (widget.isLight ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.10))), boxShadow: widget.isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0,6))] : []),
      child: Row(
        children: [
          Expanded(child: TextField(
            controller: widget.controller, focusNode: widget.focusNode,
            style: TextStyle(fontSize: 15, color: widget.isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)),
            decoration: InputDecoration(hintText: 'Ask Banataq anything...', hintStyle: TextStyle(fontSize: 15, color: widget.isLight ? Colors.black.withValues(alpha: 0.38) : Colors.white.withValues(alpha: 0.42)), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            textInputAction: TextInputAction.send,
            onSubmitted: widget.onSend,
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasText ? () => widget.onSend(widget.controller.text) : null,
            child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: hasText ? const Color(0xFFD4AF5A) : (widget.isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.10))), child: Icon(Icons.arrow_upward, size: 18, color: hasText ? const Color(0xFF1A1200) : (widget.isLight ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35)))),
          ),
        ],
      ),
    );
  }
}
