import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Bottom sheet padronizado com cabeçalho + conteúdo + actions opcionais.
class ArchbaseBottomSheet extends StatelessWidget {
  const ArchbaseBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.scrollable = true,
    this.heightFactor,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool scrollable;
  final double? heightFactor;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool scrollable = true,
    double? heightFactor,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => ArchbaseBottomSheet(
        title: title,
        actions: actions,
        scrollable: scrollable,
        heightFactor: heightFactor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    final body = Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          Flexible(
            child: scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  )
                : Padding(padding: const EdgeInsets.all(20), child: child),
          ),
          if (actions != null && actions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final a in actions!) ...[a, const SizedBox(width: 8)],
                ],
              ),
            ),
        ],
      ),
    );

    final container = Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: body,
    );

    if (heightFactor == null) return container;
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: container,
    );
  }
}
