import 'package:flutter/material.dart';
import 'banataq_mark.dart';

/// Minimal launch: B → glow → BANATAQ on #060B14. No tagline, no progress bar.
/// Animation accompanies loading, not creates it.
class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});
  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))..forward();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).accessibleNavigation || MediaQuery.of(context).disableAnimations;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value.clamp(0.0, 1.0);
          // Frame 1: 0.00 dark clean, Frame 2: 0.15-0.50 B scale+opacity, Frame 3: 0.50-0.90 BANATAQ
          final bProgress = (t / 0.42).clamp(0.0, 1.0);
          final bOpacity = (t < 0.08 ? 0.0 : (t - 0.08) / 0.34).clamp(0.0, 1.0).toDouble();
          final glow = (t < 0.55 ? 0.0 : t < 0.72 ? (t - 0.55) / 0.17 : 0.0).clamp(0.0, 0.35).toDouble();
          final wordOpacity = (t < 0.52 ? 0.0 : (t - 0.52) / 0.28).clamp(0.0, 1.0).toDouble();
          final wordOffset = 6 * (1 - wordOpacity);
          return SafeArea(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Opacity(
                  opacity: reduce ? 1 : bOpacity,
                  child: Transform.scale(
                    scale: reduce ? 1 : 0.94 + 0.06 * bProgress.toDouble(),
                    child: BanataqMark(size: 84, progress: bProgress.toDouble(), glow: glow, reducedMotion: reduce, color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: wordOpacity,
                  child: Transform.translate(
                    offset: Offset(0, wordOffset),
                    child: Text('BANATAQ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 5, color: scheme.onSurface.withValues(alpha: 0.92))),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
