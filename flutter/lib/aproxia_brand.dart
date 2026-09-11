import 'package:flutter/material.dart';

abstract final class AproxiaBrand {
  static const String name = 'Aproxia';
  static const String version = '0.2.0';
  static const String channel = 'Preview';
  static const String versionLabel = 'Aproxia v$version ($channel)';
  static const String tagline = 'Calculatoarele tale. Oriunde.';
  static const String productDescription = 'Acces la distanță & suport';

  static const Color ink = Color(0xFF081A36);
  static const Color surface = Color(0xFF0D2A54);
  static const Color surfaceElevated = Color(0xFF173E73);
  static const Color accent = Color(0xFF1769E8);
  static const Color accentBright = Color(0xFF2B7CFF);
  static const Color accentSoft = Color(0xFF72C8FF);
  static const Color success = Color(0xFF2DBE60);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color canvas = Color(0xFFF4F8FD);
  static const Color border = Color(0xFFD8E5F4);
  static const Color text = Color(0xFF0D2246);
  static const Color muted = Color(0xFF587094);

  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 20;
}

/// Aproxia v0.2 identity mark: a luminous A, orbital connection stroke and spark.
class AproxiaMark extends StatelessWidget {
  const AproxiaMark({super.key, this.size = 64, this.showTile = true});

  final double size;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _AproxiaMarkPainter(),
    );
    if (!showTile) return SizedBox.square(dimension: size, child: mark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64C8FF), Color(0xFF2B7CFF), Color(0xFF1558C8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AproxiaBrand.accent.withOpacity(.30),
            blurRadius: size * .28,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: mark,
    );
  }
}

class _AproxiaMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final glow = Paint()
      ..color = const Color(0xFF4DA6FF).withOpacity(.26)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .19
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final aPath = Path()
      ..moveTo(w * .21, h * .76)
      ..lineTo(w * .46, h * .23)
      ..quadraticBezierTo(w * .50, h * .14, w * .56, h * .25)
      ..lineTo(w * .79, h * .76);
    canvas.drawPath(aPath, glow);

    final main = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8AD9FF), Color(0xFF2B7CFF), Color(0xFF1558C8)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(aPath, main);

    final highlight = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFBDEAFF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .39, h * .55), Offset(w * .63, h * .55), highlight);

    final orbit = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF70D3FF), Color(0xFF236FF0)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .045
      ..strokeCap = StrokeCap.round;
    final orbitPath = Path()
      ..moveTo(w * .16, h * .72)
      ..quadraticBezierTo(w * .48, h * .91, w * .86, h * .49);
    canvas.drawPath(orbitPath, orbit);

    final spark = Paint()..color = const Color(0xFF9EE7FF);
    final c = Offset(w * .78, h * .17);
    canvas.drawCircle(c, w * .025, spark);
    final sparkLine = Paint()
      ..color = const Color(0xFFD7F5FF)
      ..strokeWidth = w * .02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - w * .09), Offset(c.dx, c.dy + w * .09), sparkLine);
    canvas.drawLine(Offset(c.dx - w * .09, c.dy), Offset(c.dx + w * .09, c.dy), sparkLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
