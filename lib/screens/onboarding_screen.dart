// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/storage_service.dart';

// Premium cinematic onboarding — "Banataq reveals itself".
// Dark #070707 base, video as hero, minimal chrome, staggered motion.

class OnboardingScreen extends StatelessWidget {
  final StorageService storage;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.storage,
    required this.onComplete,
  });

  Future<void> _finish(BuildContext context) async {
    await storage.setOnboardingComplete();
    if (!context.mounted) return;
    onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingBody(onFinish: () => _finish(context));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Data
// ──────────────────────────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String? videoAsset;
  final String? imageAsset;
  final String label;
  final String title;
  final String body;
  final String? footnote;
  final List<String> prompts;
  final Color accent;

  const _OnboardingPageData({
    this.videoAsset,
    this.imageAsset,
    required this.label,
    required this.title,
    required this.body,
    this.footnote,
    this.prompts = const [],
    required this.accent,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Body state — PageView + video preloading + content animation
// ──────────────────────────────────────────────────────────────────────────────

class _OnboardingBody extends StatefulWidget {
  final VoidCallback onFinish;
  const _OnboardingBody({required this.onFinish});

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _contentController;
  int _page = 0;

  // Video controllers — intelligent preload: current + next (+ previous kept).
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoReady = {};

  static const _gold = Color(0xFFD4AF5A);

  late final List<_OnboardingPageData> _pages = [
    const _OnboardingPageData(
      videoAsset: 'assets/onboarding/welcome.mp4',
      label: 'MEET BANATAQ',
      title: 'AI that helps\nyou get things done.',
      body: 'Study. Work. Create. Sell.\nCommunicate. Solve.',
      footnote: 'Born in Africa. Built for the world.',
      accent: _gold,
    ),
    const _OnboardingPageData(
      videoAsset: 'assets/onboarding/study.mp4',
      label: 'LEARN',
      title: 'Learn without\nthe confusion.',
      body:
          'Understand difficult things, practice what you\'re learning, and move forward with confidence.',
      prompts: [
        'Explain this like I\'m a beginner.',
        'Quiz me on this topic.',
        'Summarize my notes.',
      ],
      accent: Color(0xFF2E7D32),
    ),
    const _OnboardingPageData(
      videoAsset: 'assets/onboarding/business.mp4',
      label: 'WORK & BUSINESS',
      title: 'Turn ideas\ninto action.',
      body:
          'Write faster, serve customers, organize your work, and build your business.',
      prompts: [
        'Write a message to my customer.',
        'Create a product description.',
        'Help me plan my week.',
      ],
      accent: Color(0xFF1565C0),
    ),
    const _OnboardingPageData(
      videoAsset: 'assets/onboarding/create4.mp4',
      label: 'CREATE',
      title: 'Create. Write.\nCommunicate.',
      body:
          'Turn your thoughts into ideas, content, conversations, and something real.',
      prompts: [
        'Give me 10 content ideas.',
        'Rewrite this professionally.',
        'Translate this for me.',
      ],
      accent: Color(0xFF6A1B9A),
    ),
    const _OnboardingPageData(
      videoAsset: 'assets/onboarding/everyday.mp4',
      label: 'EVERYDAY LIFE',
      title: 'Whatever you\'re\nfiguring out.',
      body:
          'Ask questions, understand information, plan your next step, and solve everyday problems.',
      footnote: 'One assistant. Many possibilities.',
      prompts: [
        'Explain this document.',
        'Help me plan my day.',
        'What should I do first?',
      ],
      accent: _gold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _preloadForPage(0);
    // Preload next immediately so swipe is instant.
    if (_pages.length > 1) _preloadForPage(1);
  }

  Future<void> _preloadForPage(int index) async {
    if (index < 0 || index >= _pages.length) return;
    final asset = _pages[index].videoAsset;
    if (asset == null) return;
    if (_videoControllers.containsKey(index)) return;
    final c = VideoPlayerController.asset(asset);
    _videoControllers[index] = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.setPlaybackSpeed(index == 1 ? 7.0 : 2.2);
      c.addListener(() {
        if (!c.value.isInitialized) return;
        final dur = c.value.duration;
        if (dur == Duration.zero) return;
        if (c.value.position >= dur) {
          c.seekTo(Duration.zero);
          c.play();
        }
      });
      if (index == _page) {
        await c.play();
      }
      if (mounted) setState(() => _videoReady[index] = true);
    } catch (_) {
      if (mounted) setState(() => _videoReady[index] = false);
    }
  }

  void _onPageChanged(int i) async {
    final prev = _page;
    setState(() => _page = i);
    _contentController.forward(from: 0);

    final prevCtrl = _videoControllers[prev];
    if (prevCtrl != null) {
      try {
        await prevCtrl.pause();
      } catch (_) {}
    }
    await _preloadForPage(i);
    final cur = _videoControllers[i];
    if (cur != null && cur.value.isInitialized) {
      try {
        await cur.seekTo(Duration.zero);
        await cur.play();
      } catch (_) {}
    }
    _preloadForPage(i + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = _videoControllers[i];
      if (c != null && c.value.isInitialized && !c.value.isPlaying) {
        try {
          await c.play();
        } catch (_) {}
      }
    });
  }

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onFinish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    for (final c in _videoControllers.values) {
      c.pause();
      Future.microtask(() {
        try {
          c.dispose();
        } catch (_) {}
      });
    }
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF070707) : const Color(0xFFFFFEF9);
    final warmWhite = isDark ? const Color(0xFFF5F0E8) : const Color(0xFF1A1A1A);
    final muted = isDark ? const Color(0xFF9A9590) : const Color(0xFF6B7280);
    final isLast = _page == _pages.length - 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — BANATAQ + Skip (only on last page)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'BANATAQ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: warmWhite.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: isLast ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !isLast,
                      child: GestureDetector(
                        onTap: widget.onFinish,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView — video + story
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) {
                  final data = _pages[i];
                  final isActive = i == _page;
                  return _OnboardingPageView(
                    data: data,
                    isActive: isActive,
                    controller: _videoControllers[i],
                    isReady: _videoReady[i] == true,
                    contentController: _contentController,
                    reduceMotion: reduceMotion,
                    warmWhite: warmWhite,
                    muted: muted,
                    bg: bg,
                  );
                },
              ),
            ),

            // Progress — always visible
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _Progress(segments: _pages.length, active: _page),
            ),
            // CTA — only on last page
            AnimatedOpacity(
              opacity: isLast ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !isLast,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: _CTA(
                    isLast: true,
                    onTap: _next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Page view — video hero + story
// ──────────────────────────────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;
  final VideoPlayerController? controller;
  final bool isReady;
  final AnimationController contentController;
  final bool reduceMotion;
  final Color warmWhite;
  final Color muted;
  final Color bg;

  const _OnboardingPageView({
    required this.data,
    required this.isActive,
    required this.controller,
    required this.isReady,
    required this.contentController,
    required this.reduceMotion,
    required this.warmWhite,
    required this.muted,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Video occupies 48–58% of visual attention.
        final videoHeight = (constraints.maxHeight * 0.52)
            .clamp(220.0, 420.0)
            .toDouble();
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Video — cinematic frame, never cropped
                _VideoFrame(
                  data: data,
                  controller: controller,
                  isReady: isReady,
                  isActive: isActive,
                  height: videoHeight,
                  bg: bg,
                ),
                const SizedBox(height: 22),
                // Story label
                _Staggered(
                  visible: isActive,
                  delayMs: 60,
                  reduceMotion: reduceMotion,
                  controller: contentController,
                  child: _StoryLabel(label: data.label, accent: data.accent),
                ),
                const SizedBox(height: 10),
                // Headline
                _Staggered(
                  visible: isActive,
                  delayMs: 120,
                  reduceMotion: reduceMotion,
                  controller: contentController,
                  child: Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      height: 1.06,
                      letterSpacing: -0.5,
                      color: warmWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Body
                _Staggered(
                  visible: isActive,
                  delayMs: 180,
                  reduceMotion: reduceMotion,
                  controller: contentController,
                  child: Text(
                    data.body,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.48,
                      color: muted,
                    ),
                  ),
                ),
                if (data.footnote != null) ...[
                  const SizedBox(height: 14),
                  _Staggered(
                    visible: isActive,
                    delayMs: 220,
                    reduceMotion: reduceMotion,
                    controller: contentController,
                    child: Text(
                      data.footnote!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: warmWhite.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
                if (data.prompts.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _PromptChips(
                    prompts: data.prompts,
                    accent: data.accent,
                    visible: isActive,
                    reduceMotion: reduceMotion,
                    controller: contentController,
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Video frame — contain, rounded, vignette, watermark fade, smooth transition
// ──────────────────────────────────────────────────────────────────────────────

class _VideoFrame extends StatelessWidget {
  final _OnboardingPageData data;
  final VideoPlayerController? controller;
  final bool isReady;
  final bool isActive;
  final double height;
  final Color bg;

  const _VideoFrame({
    required this.data,
    required this.controller,
    required this.isReady,
    required this.isActive,
    required this.height,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = data.videoAsset != null;

    Widget child;
    if (hasVideo && controller != null && isReady) {
      child = _buildVideo(context);
    } else if (data.imageAsset != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          data.imageAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildPlaceholder(context),
        ),
      );
    } else if (hasVideo) {
      // Still loading — show placeholder with fade, no black flash.
      child = _buildPlaceholder(context);
    } else {
      child = _buildPlaceholder(context);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey('${data.label}_$isReady'),
        height: height,
        child: child,
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    final c = controller!;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video — fill the box (cover, no black bars)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width == 0 ? 720 : c.value.size.width,
                  height: c.value.size.height == 0 ? 1280 : c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            // Soft vignette
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            // Watermark protection — integrated dark fade, not a hard bar.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.55, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: Text(
                  'BANATAQ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final accent = data.accent;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _GeometricPainter(color: accent),
            size: Size.infinite,
          ),
          Icon(iconForLabel(data.label), size: 64, color: accent.withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  IconData iconForLabel(String label) {
    switch (label) {
      case 'MEET BANATAQ':
        return Icons.waving_hand_rounded;
      case 'LEARN':
        return Icons.school_rounded;
      case 'WORK & BUSINESS':
        return Icons.storefront_rounded;
      case 'CREATE':
        return Icons.palette_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _GeometricPainter extends CustomPainter {
  final Color color;
  _GeometricPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const s = 44.0;
    for (double x = -size.height; x < size.width + size.height; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
      canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), p);
    }
    final c = Paint()..color = color.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18), 42, c);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 52, c);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────────────────────
// Story label
// ──────────────────────────────────────────────────────────────────────────────

class _StoryLabel extends StatelessWidget {
  final String label;
  final Color accent;
  const _StoryLabel({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 1.5, color: accent.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: accent.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Prompt chips — tiny Banataq suggestions
// ──────────────────────────────────────────────────────────────────────────────

class _PromptChips extends StatelessWidget {
  final List<String> prompts;
  final Color accent;
  final bool visible;
  final bool reduceMotion;
  final AnimationController controller;

  const _PromptChips({
    required this.prompts,
    required this.accent,
    required this.visible,
    required this.reduceMotion,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(prompts.length, (i) {
        return _Staggered(
          visible: visible,
          delayMs: 240 + i * 90,
          reduceMotion: reduceMotion,
          controller: controller,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              prompts[i],
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.72)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Progress — five tiny segments
// ──────────────────────────────────────────────────────────────────────────────

class _Progress extends StatelessWidget {
  final int segments;
  final int active;
  const _Progress({required this.segments, required this.active});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(segments, (i) {
        final isActive = i == active;
        final isPast = i < active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 8),
          width: isActive ? 28 : 14,
          height: 3.5,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFD4AF5A)
                : isPast
                    ? const Color(0xFFD4AF5A).withValues(alpha: 0.38)
                    : isLight
                        ? Colors.black.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CTA — gold, 56px, 16px radius
// ──────────────────────────────────────────────────────────────────────────────

class _CTA extends StatefulWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _CTA({required this.isLast, required this.onTap});

  @override
  State<_CTA> createState() => _CTAState();
}

class _CTAState extends State<_CTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF5A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF5A).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.isLast ? 'Get started' : 'Continue',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1200),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Staggered motion helper
// ──────────────────────────────────────────────────────────────────────────────

class _Staggered extends StatelessWidget {
  final bool visible;
  final int delayMs;
  final bool reduceMotion;
  final AnimationController controller;
  final Widget child;

  const _Staggered({
    required this.visible,
    required this.delayMs,
    required this.reduceMotion,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    final start = (delayMs / 700).clamp(0.0, 0.9);
    final interval = Interval(start, 1.0, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = interval.transform(controller.value);
        final opacity = visible ? t : 0.0;
        final dy = (1 - t) * 12;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, visible ? dy : 12),
            child: child,
          ),
        );
      },
    );
  }
}
