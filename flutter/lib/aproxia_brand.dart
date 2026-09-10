import 'package:flutter/material.dart';

/// Central Aproxia product identity used by the custom desktop experience.
///
/// Keep branding values here instead of scattering them through the RustDesk
/// codebase. This makes upstream merges substantially easier.
abstract final class AproxiaBrand {
  static const String name = 'Aproxia';
  static const String tagline = 'Your computers. Anywhere.';
  static const String productDescription = 'Remote Access & Support';

  // Premium visual language: deep navy surfaces with a clear cyan-blue accent.
  // These are intentionally defined as semantic tokens so the palette can be
  // tuned without touching individual widgets.
  static const Color ink = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111B2E);
  static const Color surfaceElevated = Color(0xFF17243A);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentSoft = Color(0xFF60A5FA);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 20;
}
