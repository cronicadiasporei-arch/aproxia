import 'package:flutter/material.dart';

abstract final class AproxiaBrand {
  static const String name = 'Aproxia';
  static const String version = '1.0.1';
  static const String channel = '';
  static const String versionLabel = 'Aproxia v$version';
  static const String tagline = 'Calculatoarele tale. Oriunde.';
  static const String productDescription = 'Acces la distanță & suport';

  static const Color ink = Color(0xFF061A35);
  static const Color surface = Color(0xFF0B2B58);
  static const Color surfaceElevated = Color(0xFF123F75);
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

  static const String logoAsset = 'assets/aproxia/aproxia_logo.png';
  static const String sidebarGlobeAsset = 'assets/aproxia/aproxia_sidebar_globe.png';
  static const String worldMapAsset = 'assets/aproxia/aproxia_world_map.png';
}

class AproxiaMark extends StatelessWidget {
  const AproxiaMark({super.key, this.size = 64, this.showTile = false});

  final double size;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      AproxiaBrand.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    if (!showTile) {
      return SizedBox.square(dimension: size, child: mark);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .06),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2F61), Color(0xFF071D3C)],
        ),
        border: Border.all(color: const Color(0x334FC3FF)),
        boxShadow: [
          BoxShadow(
            color: AproxiaBrand.accent.withOpacity(.22),
            blurRadius: size * .28,
            offset: Offset(0, size * .07),
          ),
        ],
      ),
      child: mark,
    );
  }
}
