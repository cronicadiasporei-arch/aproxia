import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class AproxiaBrand {
  static const String name = 'Aproxia';
  static const String version = '1.0.0';
  static const String channel = '';
  static const String versionLabel = 'Aproxia v$version';
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

  static const String logoAsset = 'assets/aproxia/logo.svg';
  static const String sidebarGlobeAsset = 'assets/aproxia/sidebar_globe.svg';
  static const String worldMapAsset = 'assets/aproxia/world_map.svg';
}

/// Aproxia v1 identity mark. The same vector asset is used throughout the app
/// so the sidebar, installer and future About page keep one consistent brand.
class AproxiaMark extends StatelessWidget {
  const AproxiaMark({super.key, this.size = 64, this.showTile = true});

  final double size;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      AproxiaBrand.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showTile) {
      return SizedBox.square(dimension: size, child: mark);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2F61), Color(0xFF0A2348)],
        ),
        border: Border.all(color: const Color(0x334FC3FF)),
        boxShadow: [
          BoxShadow(
            color: AproxiaBrand.accent.withOpacity(.26),
            blurRadius: size * .30,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: mark,
    );
  }
}
