import 'package:flutter/material.dart';

abstract final class AproxiaBrand {
  static const String name = 'Aproxia';
  static const String tagline = 'Calculatoarele tale. Oriunde.';
  static const String productDescription = 'Acces la distanță & suport';

  static const Color ink = Color(0xFF0B1F3A);
  static const Color surface = Color(0xFF102746);
  static const Color surfaceElevated = Color(0xFF17365D);
  static const Color accent = Color(0xFF3478F6);
  static const Color accentSoft = Color(0xFF67B7FF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color canvas = Color(0xFFF5F8FC);
  static const Color border = Color(0xFFDCE6F2);
  static const Color text = Color(0xFF102A52);
  static const Color muted = Color(0xFF6B7F96);

  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 20;
}

/// Premium Aproxia identity mark used throughout the Windows UI.
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
    if (!showTile) return mark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF73D1FF), Color(0xFF3478F6), Color(0xFF155CD6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AproxiaBrand.accent.withOpacity(.30),
            blurRadius: size * .30,
            offset: Offset(0, size * .10),
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

    final main = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFDDEEFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(w * .24, h * .72)
      ..lineTo(w * .47, h * .26)
      ..quadraticBezierTo(w * .50, h * .20, w * .54, h * .28)
      ..lineTo(w * .75, h * .72);
    canvas.drawPath(left, main);

    final cross = Paint()
      ..color = Colors.white.withOpacity(.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .095
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .38, h * .53), Offset(w * .62, h * .53), cross);

    final swoosh = Paint()
      ..color = const Color(0xFF8BD8FF).withOpacity(.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .055
      ..strokeCap = StrokeCap.round;
    final swooshPath = Path()
      ..moveTo(w * .20, h * .73)
      ..quadraticBezierTo(w * .50, h * .86, w * .82, h * .54);
    canvas.drawPath(swooshPath, swoosh);

    final sparkle = Paint()..color = const Color(0xFFBEE9FF);
    final c = Offset(w * .76, h * .20);
    canvas.drawCircle(c, w * .028, sparkle);
    canvas.drawLine(Offset(c.dx, c.dy - w * .08), Offset(c.dx, c.dy + w * .08), Paint()..color = const Color(0xFFBEE9FF)..strokeWidth = w * .018..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(c.dx - w * .08, c.dy), Offset(c.dx + w * .08, c.dy), Paint()..color = const Color(0xFFBEE9FF)..strokeWidth = w * .018..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
