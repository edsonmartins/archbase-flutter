import 'package:flutter/material.dart';

import 'archbase_colors.dart';
import 'archbase_theme.dart';

/// Açúcar sintático para acessar os tokens semânticos do tema atual.
extension ArchbaseThemeContextX on BuildContext {
  ArchbaseThemeColors get archbase {
    final ext = Theme.of(this).extension<ArchbaseThemeColors>();
    if (ext == null) {
      throw FlutterError(
        'ArchbaseThemeColors não está instalado. Use ArchbaseTheme.light/dark '
        'para construir o ThemeData.',
      );
    }
    return ext;
  }

  ArchbaseColors get archbaseColors => archbase.archbase;

  /// Cor adequada ao tema (light/dark) escolhendo entre dois valores.
  Color archbaseDual(Color light, Color dark) {
    return Theme.of(this).brightness == Brightness.light ? light : dark;
  }

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
