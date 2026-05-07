import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../feedback/archbase_loading.dart';

enum ArchbaseButtonVariant { primary, secondary, ghost, danger }

enum ArchbaseButtonSize { small, medium, large }

/// Botão padrão da archbase com variantes e estado de loading embutido.
class ArchbaseButton extends StatelessWidget {
  const ArchbaseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ArchbaseButtonVariant.primary,
    this.size = ArchbaseButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final ArchbaseButtonVariant variant;
  final ArchbaseButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool isLoading;
  final bool fullWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final padding = _padding();
    final disabled = isLoading || onPressed == null;
    final colors = context.archbaseColors;

    Widget content;
    if (isLoading) {
      content = const ArchbaseInlineLoading(color: Colors.white);
    } else if (icon != null) {
      final iconWidget = Icon(icon, size: _iconSize());
      final labelWidget = Flexible(
        child: Text(label, overflow: TextOverflow.ellipsis),
      );
      content = Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: iconRight
            ? [labelWidget, const SizedBox(width: 8), iconWidget]
            : [iconWidget, const SizedBox(width: 8), labelWidget],
      );
    } else {
      content = Text(label, overflow: TextOverflow.ellipsis);
    }

    Widget button;
    switch (variant) {
      case ArchbaseButtonVariant.primary:
        button = ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(padding: padding),
          child: content,
        );
        break;
      case ArchbaseButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(padding: padding),
          child: content,
        );
        break;
      case ArchbaseButtonVariant.ghost:
        button = TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(padding: padding),
          child: content,
        );
        break;
      case ArchbaseButtonVariant.danger:
        button = ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            padding: padding,
          ),
          child: content,
        );
        break;
    }

    final wrapped = fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
    return tooltip == null ? wrapped : Tooltip(message: tooltip!, child: wrapped);
  }

  EdgeInsets _padding() {
    switch (size) {
      case ArchbaseButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case ArchbaseButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ArchbaseButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  double _iconSize() {
    switch (size) {
      case ArchbaseButtonSize.small:
        return 16;
      case ArchbaseButtonSize.medium:
        return 18;
      case ArchbaseButtonSize.large:
        return 22;
    }
  }
}
