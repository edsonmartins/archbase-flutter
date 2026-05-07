import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';

enum ArchbaseAlertSeverity { info, success, warning, error }

/// Diálogo informativo (1 botão).
class ArchbaseAlertDialog extends StatelessWidget {
  const ArchbaseAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.severity = ArchbaseAlertSeverity.info,
    this.actionLabel = 'OK',
  });

  final String title;
  final String message;
  final ArchbaseAlertSeverity severity;
  final String actionLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    ArchbaseAlertSeverity severity = ArchbaseAlertSeverity.info,
    String actionLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ArchbaseAlertDialog(
        title: title,
        message: message,
        severity: severity,
        actionLabel: actionLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbaseColors;
    final (icon, color) = switch (severity) {
      ArchbaseAlertSeverity.info => (LucideIcons.info, colors.info),
      ArchbaseAlertSeverity.success =>
        (LucideIcons.circleCheck, colors.success),
      ArchbaseAlertSeverity.warning =>
        (LucideIcons.triangleAlert, colors.warning),
      ArchbaseAlertSeverity.error =>
        (LucideIcons.circleAlert, colors.error),
    };

    return AlertDialog(
      icon: Icon(icon, color: color, size: 32),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Toast/SnackBar padronizado (utilitário sem widget).
class ArchbaseToast {
  ArchbaseToast._();

  static void show(
    BuildContext context, {
    required String message,
    ArchbaseAlertSeverity severity = ArchbaseAlertSeverity.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final color = switch (severity) {
      ArchbaseAlertSeverity.info => Colors.blue.shade700,
      ArchbaseAlertSeverity.success => Colors.green.shade700,
      ArchbaseAlertSeverity.warning => Colors.orange.shade700,
      ArchbaseAlertSeverity.error => Colors.red.shade700,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
        action: action,
      ),
    );
  }
}
