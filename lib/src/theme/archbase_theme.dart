import 'package:flutter/material.dart';

import 'archbase_colors.dart';
import 'archbase_text_styles.dart';

/// Constrói `ThemeData` (light/dark) a partir dos tokens da archbase.
class ArchbaseTheme {
  ArchbaseTheme._();

  static ThemeData light({
    ArchbaseColors colors = const ArchbaseColors(),
    ArchbaseFontScale fontScale = ArchbaseFontScale.normal,
    String? fontFamily,
    bool highContrast = false,
  }) {
    final scheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      surface: colors.surfaceLight,
      onSurface: colors.textPrimaryLight,
      error: colors.error,
      onError: Colors.white,
    );
    return _build(
      scheme: scheme,
      brightness: Brightness.light,
      colors: colors,
      backgroundColor: colors.backgroundLight,
      cardColor: colors.cardLight,
      textPrimary: colors.textPrimaryLight,
      textSecondary: colors.textSecondaryLight,
      borderColor: highContrast ? colors.textPrimaryLight : colors.borderLight,
      fontScale: fontScale,
      fontFamily: fontFamily,
    );
  }

  static ThemeData dark({
    ArchbaseColors colors = const ArchbaseColors(),
    ArchbaseFontScale fontScale = ArchbaseFontScale.normal,
    String? fontFamily,
    bool highContrast = false,
  }) {
    final scheme = ColorScheme.dark(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      surface: colors.surfaceDark,
      onSurface: colors.textPrimaryDark,
      error: colors.error,
      onError: Colors.white,
    );
    return _build(
      scheme: scheme,
      brightness: Brightness.dark,
      colors: colors,
      backgroundColor: colors.backgroundDark,
      cardColor: colors.cardDark,
      textPrimary: colors.textPrimaryDark,
      textSecondary: colors.textSecondaryDark,
      borderColor: highContrast ? colors.textPrimaryDark : colors.borderDark,
      fontScale: fontScale,
      fontFamily: fontFamily,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Brightness brightness,
    required ArchbaseColors colors,
    required Color backgroundColor,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required ArchbaseFontScale fontScale,
    String? fontFamily,
  }) {
    final textTheme = ArchbaseTextStyles.buildTextTheme(
      primaryColor: textPrimary,
      secondaryColor: textSecondary,
      scale: fontScale,
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primary),
      ),
      dividerColor: borderColor,
      dividerTheme:
          DividerThemeData(color: borderColor, space: 1, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: colors.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      extensions: [
        ArchbaseThemeColors(
          archbase: colors,
          background: backgroundColor,
          card: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          border: borderColor,
        ),
      ],
    );
  }
}

/// Extension instalada em [ThemeData.extensions] para que widgets acessem
/// tokens semânticos via `Theme.of(context).extension<ArchbaseThemeColors>()`.
class ArchbaseThemeColors extends ThemeExtension<ArchbaseThemeColors> {
  ArchbaseThemeColors({
    required this.archbase,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final ArchbaseColors archbase;
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  @override
  ArchbaseThemeColors copyWith({
    ArchbaseColors? archbase,
    Color? background,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) {
    return ArchbaseThemeColors(
      archbase: archbase ?? this.archbase,
      background: background ?? this.background,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
    );
  }

  @override
  ArchbaseThemeColors lerp(
      ThemeExtension<ArchbaseThemeColors>? other, double t) {
    if (other is! ArchbaseThemeColors) return this;
    return ArchbaseThemeColors(
      archbase: archbase,
      background: Color.lerp(background, other.background, t) ?? background,
      card: Color.lerp(card, other.card, t) ?? card,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}
