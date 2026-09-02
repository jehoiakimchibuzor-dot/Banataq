import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

Future<Uint8List> _render(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  // bg #080808 rounded
  final bg = const Color(0xFF080808);
  canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = bg);
  // tile
  final strokeW = s * 0.06;
  final tile = RRect.fromRectAndRadius(
    Rect.fromLTWH(strokeW * 0.9, strokeW * 0.9, s - strokeW * 1.8, s - strokeW * 1.8),
    Radius.circular(s * 0.24),
  );
  final tilePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFFD4AF37);
  canvas.drawRRect(tile, tilePaint);
  // B glyph
  final tp = TextPainter(
    text: const TextSpan(text: 'B', style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Color(0xFFF8F6F0))),
    textDirection: TextDirection.ltr,
  );
  // scale to 0.52 * s
  final targetSize = s * 0.52;
  // layout at 100 then scale
  tp.layout();
  final scale = targetSize / tp.height;
  tp.text = TextSpan(text: 'B', style: TextStyle(fontSize: 100 * scale, fontWeight: FontWeight.w900, color: const Color(0xFFF8F6F0)));
  tp.layout();
  final bW = tp.width; final bH = tp.height;
  final left = (s - bW) / 2;
  final top = (s - bH) / 2 - s * 0.02;
  tp.paint(canvas, Offset(left, top));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sizes = {512: 'assets/icon/b_icon_512.png', 192: 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 144: 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 96: 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 72: 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 48: 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'};
  for (final e in sizes.entries) {
    final bytes = await _render(e.key);
    final f = File(e.value);
    await f.create(recursive: true);
    await f.writeAsBytes(bytes);
    print('wrote ${e.value} ${bytes.length}');
    if (e.key == 192) {
      final f2 = File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png');
      await f2.writeAsBytes(bytes);
      print('wrote round');
    }
  }
  // also 1024 for play store
  final big = await _render(1024);
  await File('assets/icon/b_icon_1024.png').create(recursive: true).then((f) => f.writeAsBytes(big));
  print('done');
  exit(0);
}
