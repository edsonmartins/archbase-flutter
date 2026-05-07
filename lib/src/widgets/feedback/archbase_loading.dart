import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Spinner com label opcional, centralizado.
class ArchbaseLoading extends StatelessWidget {
  const ArchbaseLoading({
    super.key,
    this.label,
    this.size = 40,
    this.color,
    this.padding = const EdgeInsets.all(24),
  });

  final String? label;
  final double size;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.archbaseColors.primary;
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                color: c,
                strokeWidth: 3,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading inline (linha horizontal pequena) — usa em botões e cards.
class ArchbaseInlineLoading extends StatelessWidget {
  const ArchbaseInlineLoading({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? context.archbaseColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}
