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

/// Vector Aproxia mark used in the app shell and sidebar.
/// The two linked strokes represent two endpoints joined through the network.
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
          colors: [Color(0xFF69C7FF), Color(0xFF2C7FF5), Color(0xFF1765D8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AproxiaBrand.accent.withOpacity(.26),
            blurRadius: size * .25,
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
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final soft = Paint()
      ..color = Colors.white.withOpacity(.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(size.width * .30, size.height * .72)
      ..lineTo(size.width * .48, size.height * .30)
      ..lineTo(size.width * .58, size.height * .50);
    final right = Path()
      ..moveTo(size.width * .70, size.height * .72)
      ..lineTo(size.width * .52, size.height * .30)
      ..lineTo(size.width * .42, size.height * .50);

    canvas.drawPath(left, white);
    canvas.drawPath(right, soft);

    final node = Paint()..color = const Color(0xFF0B2D55);
    canvas.drawCircle(Offset(size.width * .30, size.height * .72), size.width * .055, node);
    canvas.drawCircle(Offset(size.width * .70, size.height * .72), size.width * .055, node);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
