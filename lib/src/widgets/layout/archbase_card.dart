import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Status visual aplicável a um card (faixa colorida à esquerda + ícone).
class ArchbaseCardStatus {
  const ArchbaseCardStatus({
    required this.color,
    this.icon,
    this.label,
  });

  final Color color;
  final IconData? icon;
  final String? label;
}

/// Card padrão da archbase.
///
/// Estrutura: status bar lateral + cabeçalho + body. Use [onTap] para
/// transformar em item clicável (com ripple e hover).
class ArchbaseCard extends StatelessWidget {
  const ArchbaseCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.body,
    this.footer,
    this.status,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? body;
  final Widget? footer;
  final ArchbaseCardStatus? status;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.archbase;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: colors.card,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (status != null)
                  Container(
                    width: 4,
                    color: status!.color,
                  ),
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null ||
                            leading != null ||
                            trailing != null)
                          Row(
                            children: [
                              if (leading != null) ...[
                                leading!,
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (title != null)
                                      Text(
                                        title!,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (subtitle != null)
                                      Text(
                                        subtitle!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (status != null && status!.label != null)
                                _StatusChip(status: status!),
                              if (trailing != null) ...[
                                const SizedBox(width: 8),
                                trailing!,
                              ],
                            ],
                          ),
                        if (body != null) ...[
                          const SizedBox(height: 10),
                          body!,
                        ],
                        if (footer != null) ...[
                          const SizedBox(height: 10),
                          Divider(color: colors.border, height: 1),
                          const SizedBox(height: 8),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: margin,
      child: card,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ArchbaseCardStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.icon != null) ...[
            Icon(status.icon, size: 12, color: status.color),
            const SizedBox(width: 4),
          ],
          Text(
            status.label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
