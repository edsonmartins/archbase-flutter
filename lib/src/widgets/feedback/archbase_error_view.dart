import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Widget de erro reutilizável (full-screen ou inline).
class ArchbaseErrorView extends StatelessWidget {
  const ArchbaseErrorView({
    super.key,
    required this.message,
    this.title = 'Algo deu errado',
    this.icon = LucideIcons.circleAlert,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.compact = false,
  });

  final String message;
  final String title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbaseColors;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: colors.error),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.rotateCw),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
