import 'package:flutter/material.dart';

/// Single geometric BANATAQ B — the brand DNA.
/// Not a font glyph. Custom, rounded, slightly futuristic, legible at 20px.
/// Used for app icon, launch, AI avatar, thinking indicator — same geometry everywhere.
class BanataqMark extends StatelessWidget {
  final double size;
  final Color? color;
  final double glow; // 0..1
  final double progress; // 0..1 construction
  final bool reducedMotion;
  const BanataqMark({super.key, this.size = 96, this.color, this.glow = 0, this.progress = 1, this.reducedMotion = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFD4AF5A);
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _BMarkPainter(color: c, glow: reducedMotion ? 0 : glow, progress: reducedMotion ? 1 : progress.clamp(0, 1)),
      ),
    );
  }
}

class _BMarkPainter extends CustomPainter {
  final Color color; final double glow; final double progress;
  _BMarkPainter({required this.color, required this.glow, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.06;
    // Tile
    final tile = RRect.fromRectAndRadius(Rect.fromLTWH(stroke*0.4, stroke*0.4, s - stroke*0.8, s - stroke*0.8), Radius.circular(s*0.24));
    final tilePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.95);
    final path = Path()..addRRect(tile);
    final m = path.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * progress), tilePaint);
    if (glow > 0) {
      final g = Paint()..style=PaintingStyle.stroke..strokeWidth=stroke+8*glow..color=color.withValues(alpha:0.18*glow)..maskFilter=MaskFilter.blur(BlurStyle.normal, 10*glow);
      canvas.drawPath(m.extractPath(0, m.length), g);
    }
    // Font B
    final tp = TextPainter(text: TextSpan(text:'B', style: TextStyle(fontSize: s*0.52, fontWeight: FontWeight.w900, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
    final bW = tp.width; final bH = tp.height;
    final left = (s - bW)/2; final top = (s - bH)/2;
    final reveal = (progress*1.15).clamp(0.0, 1.0);
    canvas.save(); canvas.clipRect(Rect.fromLTWH(left, top, bW*reveal, bH));
    tp.paint(canvas, Offset(left, top));
    canvas.restore();
    if (reveal>0.02 && reveal<0.98) canvas.drawCircle(Offset(left+bW*reveal, top+bH/2), stroke*0.55, Paint()..color=color);
  }

  @override
  bool shouldRepaint(covariant _BMarkPainter o) => o.color != color || o.glow != glow || o.progress != progress;
}
