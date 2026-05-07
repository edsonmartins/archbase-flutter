import 'package:flutter/material.dart';

/// Família de tamanhos para acessibilidade (escala global).
enum ArchbaseFontScale { small, normal, large, xlarge }

extension ArchbaseFontScaleX on ArchbaseFontScale {
  double get factor {
    switch (this) {
      case ArchbaseFontScale.small:
        return 0.9;
      case ArchbaseFontScale.normal:
        return 1.0;
      case ArchbaseFontScale.large:
        return 1.15;
      case ArchbaseFontScale.xlarge:
        return 1.3;
    }
  }
}

class ArchbaseTextStyles {
  ArchbaseTextStyles._();

  static TextTheme buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    ArchbaseFontScale scale = ArchbaseFontScale.normal,
    String? fontFamily,
  }) {
    final s = scale.factor;
    TextStyle base(double size, FontWeight weight, Color color) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size * s,
        fontWeight: weight,
        color: color,
      );
    }

    return TextTheme(
      displayLarge: base(32, FontWeight.bold, primaryColor),
      displayMedium: base(28, FontWeight.bold, primaryColor),
      displaySmall: base(24, FontWeight.w600, primaryColor),
      headlineLarge: base(22, FontWeight.w700, primaryColor),
      headlineMedium: base(20, FontWeight.w700, primaryColor),
      headlineSmall: base(18, FontWeight.w600, primaryColor),
      titleLarge: base(18, FontWeight.w600, primaryColor),
      titleMedium: base(16, FontWeight.w600, primaryColor),
      titleSmall: base(14, FontWeight.w600, primaryColor),
      bodyLarge: base(16, FontWeight.normal, primaryColor),
      bodyMedium: base(14, FontWeight.normal, primaryColor),
      bodySmall: base(12, FontWeight.normal, secondaryColor),
      labelLarge: base(14, FontWeight.w600, primaryColor),
      labelMedium: base(12, FontWeight.w500, secondaryColor),
      labelSmall: base(11, FontWeight.w500, secondaryColor),
    );
  }
}
