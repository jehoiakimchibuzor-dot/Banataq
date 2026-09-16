import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection_container.dart' as di;
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/workspace/data/repositories/workspace_repository.dart';
import '../models/onboarding_preferences.dart';
import '../services/storage_service.dart';
import '../models/conversation.dart';
import 'app_shell.dart';
import 'you_screen.dart';

/// Banataq Home — Command Center.
/// Calm, premium, personal. No fake stats. Real data only.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, this.data, this.hideNavigation = false, this.onStartChat});

  final dynamic data; // kept for test compat, unused now
  final bool hideNavigation;
  final ValueChanged<String>? onStartChat;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF080808);
  static const _gold = Color(0xFFD4AF5A);
  static const _warmWhite = Color(0xFFF8F6F0);

  late final AnimationController _entrance;
  final _inputCtrl = TextEditingController();
  final _focus = FocusNode();

  OnboardingPreferences? _prefs;
  List<Conversation> _convos = [];
  List<_SpaceRow> _spaces = [];
  final List<PlatformFile> _pending = [];
  String _firstName = '';
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
    _load();
  }

  Future<void> _load() async {
    String first = '';
    String? photo;
    try {
      final authState = context.read<AuthBloc>().state;
      final u = authState.user;
      if (u != null) {
        photo = u.photoUrl;
        final n = (u.displayName ?? '').trim();
        if (n.isNotEmpty) first = n.split(RegExp(r'\s+')).first;
      }
    } catch (_) {}
    try {
      final StorageService storage = di.sl<StorageService>();
      final prefs = await storage.loadOnboardingPreferences();
      final convos = await storage.loadConversations();
      final repo = di.sl<WorkspaceRepository>();
      final ws = repo.getWorkspace();
      final spaces = <_SpaceRow>[];
      if (ws.name.isNotEmpty) {
        spaces.add(_SpaceRow(emoji: ws.emoji.isNotEmpty ? ws.emoji : '◆', title: ws.name, subtitle: ws.description, meta: ws.progressLabel ?? (ws.taskCount > 0 ? '${ws.taskDone}/${ws.taskCount}' : null)));
      }
      if (mounted) setState(() { _prefs = prefs; _convos = convos; _spaces = spaces; _firstName = first; _photoUrl = photo; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _entrance.dispose(); _inputCtrl.dispose(); _focus.dispose(); super.dispose(); }

  String get _greetingTime {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingName => _firstName.isEmpty ? 'there' : _firstName;

  String get _headline {
    final g = _prefs?.goals ?? {};
    if (g.isEmpty) return 'What are we getting done?';
    if (g.length >= 3) return 'What are we getting done?';
    if (g.contains('learn') && g.length == 1) return 'What are we learning?';
    if (g.contains('build')) return 'What are we building?';
    if (g.contains('create') && g.length == 1) return 'What are we creating?';
    if (g.contains('communicate') && g.length == 1) return 'What are we working on?';
    if (g.contains('learn')) return 'What are we learning?';
    if (g.contains('create')) return 'What are we creating?';
    return 'What are we getting done?';
  }

  List<_Quick> get _quicks {
    const study = [
      _Quick('Explain something', Icons.menu_book_outlined),
      _Quick('Quiz me', Icons.quiz_outlined),
      _Quick('Summarize notes', Icons.summarize_outlined),
      _Quick('Practice with me', Icons.edit_note_outlined),
    ];
    const business = [
      _Quick('Write to a customer', Icons.mail_outline),
      _Quick('Create an advert', Icons.campaign_outlined),
      _Quick('Plan my business', Icons.map_outlined),
      _Quick('Analyze an idea', Icons.lightbulb_outline),
    ];
    const create = [
      _Quick('Give me ideas', Icons.lightbulb_outline),
      _Quick('Write something', Icons.edit_outlined),
      _Quick('Improve my draft', Icons.auto_fix_high_outlined),
      _Quick('Create a plan', Icons.list_alt_outlined),
    ];
    const general = [
      _Quick('Help me understand', Icons.help_outline),
      _Quick('Help me plan', Icons.map_outlined),
      _Quick('Help me decide', Icons.question_mark),
      _Quick('Solve a problem', Icons.build_outlined),
    ];
    final g = _prefs?.goals ?? {};
    List<_Quick> pool = [];
    if (g.contains('learn')) {
      pool = study;
    } else if (g.contains('build')) {
      pool = business;
    } else if (g.contains('create')) {
      pool = create;
    } else if (g.contains('communicate')) {
      pool = [_Quick('Help me write', Icons.chat_bubble_outline), _Quick('Translate', Icons.translate), _Quick('Make it professional', Icons.workspace_premium_outlined), _Quick('Draft a message', Icons.mail_outline)];
    } else if (g.contains('figureThingsOut') || g.contains('getThingsDone')) {
      pool = general;
    } else {
      pool = general;
    }
    return pool.take(4).toList();
  }

  Conversation? get _recent {
    if (_convos.isEmpty) return null;
    // most recent by updatedAt
    _convos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final c = _convos.first;
    if (c.messages.isEmpty && c.title.trim().isEmpty) return null;
    return c;
  }

  // ignore: unused_element — reserved for deep-link chat routing (Phase 3)
  void _openChat(String prompt) {
    final cb = widget.onStartChat;
    if (cb != null) { cb(prompt); return; }
    // fallback: find AppShell ancestor via context
    final shell = context.findAncestorStateOfType<State<AppShell>>();
    if (shell != null) {
      // use AppShell's tap via callback not available here — push Chat directly
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Placeholder()));
      return;
    }
    // last resort: show snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prompt)));
  }

  Future<void> _pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (r == null) return;
      setState(() => _pending.addAll(r.files));
    } catch (_) {}
  }

  void _send() {
    var t = _inputCtrl.text.trim();
    if (t.isEmpty && _pending.isEmpty) return;
    if (_pending.isNotEmpty) {
      final names = _pending.map((f) => f.name).join(', ');
      t = t.isEmpty ? 'Attached files: $names' : 'Attached files: $names\n\n$t';
      _pending.clear();
    }
    HapticFeedback.selectionClick();
    final cb = widget.onStartChat;
    if (cb != null) { cb(t); _inputCtrl.clear(); setState(() {}); return; }
    _inputCtrl.clear(); setState(() {});
  }

  Widget _staggered(int i, Widget child) {
    final begin = ((i * 45).clamp(0, 420) / 520.0);
    final anim = CurvedAnimation(parent: _entrance, curve: Interval(begin, 1, curve: Curves.easeOutCubic));
    return FadeTransition(opacity: anim, child: SlideTransition(position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim), child: child));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFFAF8F4) : _bg;
    final primary = isLight ? const Color(0xFF111111) : _warmWhite;
    final muted = isLight ? const Color(0xFF6B6B6B) : const Color(0xFF9A9A9A);
    final surface = isLight ? Colors.white : const Color(0xFF121212);

    final recent = _loading ? null : _recent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverList.list(children: [
                // HEADER — BANATAQ + settings + avatar
                _staggered(0, Row(children: [
                  Text('BANATAQ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.6, color: primary.withValues(alpha: 0.88))),
                  const Spacer(),
                  IconButton(icon: Icon(Icons.settings_outlined, size: 20, color: muted), tooltip: 'Settings', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const YouScreen()))),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () { try { (context.findAncestorStateOfType() as dynamic)?.setState(() {}); } catch (_) {} },
                    child: _photoUrl != null && _photoUrl!.isNotEmpty
                        ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(_photoUrl!))
                        : Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08), border: Border.all(color: _gold.withValues(alpha: 0.25))), child: Center(child: Text(_firstName.isEmpty ? 'B' : _firstName[0].toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary)))),
                  ),
                ])),
                const SizedBox(height: 28),
                // GREETING
                _staggered(1, Text('$_greetingTime, $_greetingName.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: muted))),
                const SizedBox(height: 8),
                // HERO
                _staggered(2, Text(_headline, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -0.4, color: primary))),
                const SizedBox(height: 8),
                _staggered(3, Text('Start with a question, an idea, a task — anything.', style: TextStyle(fontSize: 13.5, height: 1.5, color: muted))),
                const SizedBox(height: 22),
                if (_pending.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [for (final f in _pending) Padding(padding: const EdgeInsets.only(right: 8), child: Stack(clipBehavior: Clip.none, children: [
                        Container(width: 150, height: 64, decoration: BoxDecoration(color: isLight ? Colors.white : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08))), padding: const EdgeInsets.all(8), child: Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFD4AF5A).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(f.extension?.toLowerCase() == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.description_outlined, size: 18, color: const Color(0xFFD4AF5A))),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(f.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? const Color(0xFF111111) : Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${(f.size/1024).toStringAsFixed(0)} KB', style: TextStyle(fontSize: 10, color: isLight ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5)))])),
                        ])),
                        Positioned(top: -8, right: -8, child: GestureDetector(onTap: () => setState(() => _pending.remove(f)), child: Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                      ]))]),
                    ),
                  ),
                _staggered(4, _HomeInput(controller: _inputCtrl, focusNode: _focus, isLight: isLight, onSend: _send, onPick: _pick, hasPending: _pending.isNotEmpty)),
                const SizedBox(height: 22),
                // QUICK START
                _staggered(5, Text('START WITH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _gold.withValues(alpha: 0.95)))),
                const SizedBox(height: 10),
                ...List.generate(_quicks.length, (i) => Padding(padding: EdgeInsets.only(bottom: i == _quicks.length - 1 ? 0 : 8), child: _staggered(6 + i, _QuickRow(quick: _quicks[i], isLight: isLight, surface: surface, onTap: () {
                  HapticFeedback.selectionClick();
                  final cb = widget.onStartChat;
                  if (cb != null) cb(_quicks[i].label);
                })))),
                if (recent != null) ...[
                  const SizedBox(height: 28),
                  _staggered(10, Text('CONTINUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _gold.withValues(alpha: 0.95)))),
                  const SizedBox(height: 10),
                  _staggered(11, _ContinueCard(conversation: recent, isLight: isLight, surface: surface, onTap: () {
                    final title = recent.title.trim().isEmpty ? 'Untitled conversation' : recent.title;
                    final cb = widget.onStartChat;
                    if (cb != null) cb('Continue: $title');
                  })),
                ],
                const SizedBox(height: 28),
                _staggered(12, Row(children: [
                  Text('YOUR SPACES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _gold.withValues(alpha: 0.95))),
                  const Spacer(),
                  if (_spaces.isNotEmpty) GestureDetector(onTap: () {
                    // tell AppShell to go to Spaces — via callback if available, else placeholder
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Spaces — switch to Spaces tab'), duration: Duration(milliseconds: 1200)));
                  }, child: Text('See all →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: muted))),
                ])),
                const SizedBox(height: 10),
                if (_spaces.isEmpty)
                  _staggered(13, _EmptySpace(isLight: isLight, surface: surface, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create your first Space — open Spaces tab'), duration: Duration(milliseconds: 1200)));
                  }))
                else
                  ...List.generate(_spaces.take(3).length, (i) => Padding(padding: EdgeInsets.only(bottom: i == 2 ? 0 : 8), child: _staggered(13 + i, _SpaceCard(space: _spaces[i], isLight: isLight, surface: surface, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ${ _spaces[i].title }')));
                  })))),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Quick { final String label; final IconData icon; const _Quick(this.label, this.icon); }
class _SpaceRow { final String emoji; final String title; final String subtitle; final String? meta; _SpaceRow({required this.emoji, required this.title, required this.subtitle, this.meta}); }

class _HomeInput extends StatefulWidget {
  final TextEditingController controller; final FocusNode focusNode; final bool isLight; final VoidCallback onSend; final VoidCallback? onPick; final bool hasPending;
  const _HomeInput({required this.controller, required this.focusNode, required this.isLight, required this.onSend, this.onPick, this.hasPending = false});
  @override
  State<_HomeInput> createState() => _HomeInputState();
}
class _HomeInputState extends State<_HomeInput> {
  @override
  void initState() { super.initState(); widget.controller.addListener(() => setState(() {})); }
  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final bg = widget.isLight ? Colors.white : const Color(0xFF181818);
    return Container(
      height: 66, padding: const EdgeInsets.fromLTRB(16, 7, 7, 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: hasText ? const Color(0xFFD4AF5A).withValues(alpha: 0.42) : (widget.isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08))), boxShadow: widget.isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0,6))] : []),
      child: Row(children: [
        Expanded(child: TextField(
          controller: widget.controller, focusNode: widget.focusNode,
          style: TextStyle(fontSize: 15, color: widget.isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)),
          decoration: InputDecoration(hintText: 'Ask Banataq anything...', hintStyle: TextStyle(fontSize: 15, color: widget.isLight ? Colors.black.withValues(alpha: 0.36) : Colors.white.withValues(alpha: 0.40)), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
          textInputAction: TextInputAction.send, onSubmitted: (_) => widget.onSend(),
        )),
        const SizedBox(width: 8),
        IconButton(icon: Icon(Icons.attach_file_rounded, size: 18, color: widget.isLight ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35)), onPressed: widget.onPick, tooltip: 'Attach file'),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: (hasText || widget.hasPending) ? widget.onSend : null,
          child: AnimatedContainer(duration: const Duration(milliseconds: 160), width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: (hasText || widget.hasPending) ? const Color(0xFFD4AF5A) : (widget.isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.08))), child: Icon(Icons.arrow_upward, size: 18, color: (hasText || widget.hasPending) ? const Color(0xFF1A1200) : (widget.isLight ? Colors.black.withValues(alpha: 0.32) : Colors.white.withValues(alpha: 0.32)))),
        ),
      ]),
    );
  }
}

class _QuickRow extends StatefulWidget {
  final _Quick quick; final bool isLight; final Color surface; final VoidCallback onTap;
  const _QuickRow({required this.quick, required this.isLight, required this.surface, required this.onTap});
  @override
  State<_QuickRow> createState() => _QuickRowState();
}
class _QuickRowState extends State<_QuickRow> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scaleByDouble(_p ? 0.99 : 1, _p ? 0.99 : 1, 1, 1),
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: BoxDecoration(
          color: _p ? const Color(0xFFD4AF5A).withValues(alpha: widget.isLight ? 0.07 : 0.09) : widget.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _p ? const Color(0xFFD4AF5A).withValues(alpha: 0.42) : (widget.isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06))),
        ),
        child: Row(children: [
          Icon(widget.quick.icon, size: 16, color: widget.isLight ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.62)),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.quick.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: widget.isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)))),
          Icon(Icons.arrow_forward, size: 14, color: _p ? const Color(0xFFD4AF5A) : (widget.isLight ? Colors.black.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.28))),
        ]),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Conversation conversation; final bool isLight; final Color surface; final VoidCallback onTap;
  const _ContinueCard({required this.conversation, required this.isLight, required this.surface, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final title = conversation.title.trim().isEmpty ? (conversation.messages.isNotEmpty ? conversation.messages.firstWhere((m) => m.fromUser, orElse: () => conversation.messages.first).text.trim().split('\n').first : 'Untitled') : conversation.title;
    final short = title.length > 48 ? '${title.substring(0, 48)}…' : title;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(padding: const EdgeInsets.fromLTRB(14, 14, 14, 12), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.07)), boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))] : []),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(short, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4), Text('Continue where you left off.', style: TextStyle(fontSize: 12.5, color: isLight ? const Color(0xFF6B6B6B) : Colors.white.withValues(alpha: 0.55))),
          const SizedBox(height: 10), Row(children: [Text('Continue →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFD4AF5A))), const Spacer(), Text(_ago(conversation.updatedAt), style: TextStyle(fontSize: 11, color: isLight ? Colors.black.withValues(alpha: 0.36) : Colors.white.withValues(alpha: 0.36)))]),
        ]),
      ),
    );
  }
  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

class _SpaceCard extends StatelessWidget {
  final _SpaceRow space; final bool isLight; final Color surface; final VoidCallback onTap;
  const _SpaceCard({required this.space, required this.isLight, required this.surface, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(padding: const EdgeInsets.fromLTRB(14, 12, 12, 12), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.07))),
        child: Row(children: [
          Text(space.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(space.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (space.subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(space.subtitle, style: TextStyle(fontSize: 12, color: isLight ? const Color(0xFF6B6B6B) : Colors.white.withValues(alpha: 0.55)), maxLines: 1, overflow: TextOverflow.ellipsis)],
          ])),
          if (space.meta != null) ...[const SizedBox(width: 8), Text(space.meta!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF5A).withValues(alpha: 0.95)))],
          const SizedBox(width: 6), Icon(Icons.chevron_right, size: 16, color: isLight ? Colors.black.withValues(alpha: 0.26) : Colors.white.withValues(alpha: 0.26)),
        ]),
      ),
    );
  }
}

class _EmptySpace extends StatelessWidget {
  final bool isLight; final Color surface; final VoidCallback onTap;
  const _EmptySpace({required this.isLight, required this.surface, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.07), style: BorderStyle.solid)),
        child: Row(children: [Icon(Icons.add, size: 16, color: const Color(0xFFD4AF5A)), const SizedBox(width: 8), Text('Create your first Space →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isLight ? const Color(0xFF111111) : const Color(0xFFF8F6F0)))]),
      ),
    );
  }
}
