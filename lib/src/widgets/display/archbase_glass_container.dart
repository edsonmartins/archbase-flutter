import 'dart:ui';

import 'package:flutter/material.dart';

/// Container com efeito glass morphism (frosted glass).
///
/// Aplica `BackdropFilter` com blur e desenha uma camada translúcida
/// por cima. Use SOBRE um background colorido/gradiente — sem fundo
/// visível, o efeito não aparece.
class ArchbaseGlassContainer extends StatelessWidget {
  const ArchbaseGlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.15,
    this.tint,
    this.borderRadius,
    this.border,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final double blur;
  final double opacity;

  /// Cor de tint do "vidro" — default branco em light, escuro em dark.
  final Color? tint;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = tint ?? (isDark ? Colors.black : Colors.white);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor.withValues(alpha: opacity),
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: glassColor.withValues(alpha: 0.25),
                  width: 1,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
