import 'package:flutter/material.dart';

/// Tokens de cor padrão da archbase. Apps podem sobrescrever via
/// `ArchbaseTheme.from(colors: MyColors())`.
class ArchbaseColors {
  const ArchbaseColors({
    this.primary = const Color(0xFF2E7D32),
    this.primaryDark = const Color(0xFF1B5E20),
    this.primaryLight = const Color(0xFFE8F5E9),
    this.secondary = const Color(0xFF1976D2),
    this.success = const Color(0xFF2E7D32),
    this.warning = const Color(0xFFFF9800),
    this.error = const Color(0xFFD32F2F),
    this.info = const Color(0xFF0288D1),
    // Light mode surfaces
    this.backgroundLight = const Color(0xFFFFFFFF),
    this.surfaceLight = const Color(0xFFF8F9FA),
    this.cardLight = const Color(0xFFFFFFFF),
    this.textPrimaryLight = const Color(0xFF1A1B1E),
    this.textSecondaryLight = const Color(0xFF6C757D),
    this.borderLight = const Color(0xFFE9ECEF),
    // Dark mode surfaces
    this.backgroundDark = const Color(0xFF121316),
    this.surfaceDark = const Color(0xFF1F2024),
    this.cardDark = const Color(0xFF272930),
    this.textPrimaryDark = const Color(0xFFE8EAED),
    this.textSecondaryDark = const Color(0xFFA1A3A8),
    this.borderDark = const Color(0xFF3A3C42),
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;

  // Status
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Light
  final Color backgroundLight;
  final Color surfaceLight;
  final Color cardLight;
  final Color textPrimaryLight;
  final Color textSecondaryLight;
  final Color borderLight;

  // Dark
  final Color backgroundDark;
  final Color surfaceDark;
  final Color cardDark;
  final Color textPrimaryDark;
  final Color textSecondaryDark;
  final Color borderDark;

  /// Paleta sugerida para gráficos (categorias).
  List<Color> get chartPalette => const [
        Color(0xFF2E7D32),
        Color(0xFF1976D2),
        Color(0xFFFF9800),
        Color(0xFFD32F2F),
        Color(0xFF00ACC1),
        Color(0xFF8E24AA),
        Color(0xFFFFB300),
        Color(0xFF5E35B1),
      ];

  /// Gradient padrão da marca.
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary],
      );
}
