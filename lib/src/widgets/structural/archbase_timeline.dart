import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

class ArchbaseTimelineItem {
  const ArchbaseTimelineItem({
    required this.title,
    this.subtitle,
    this.content,
    this.dotIcon,
    this.dotColor,
    this.timestamp,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? dotIcon;
  final Color? dotColor;
  final String? timestamp;
}

/// Timeline vertical com pontos conectados por linha. Cada item exibe
/// header + (opcional) conteúdo customizado.
class ArchbaseTimeline extends StatelessWidget {
  const ArchbaseTimeline({
    super.key,
    required this.items,
    this.dotSize = 14,
    this.lineWidth = 2,
    this.indent = 32,
    this.itemSpacing = 16,
  });

  final List<ArchbaseTimelineItem> items;
  final double dotSize;
  final double lineWidth;
  final double indent;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: indent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Dot(
                        size: dotSize,
                        color: items[i].dotColor ?? colors.archbase.primary,
                        icon: items[i].dotIcon,
                      ),
                      if (i < items.length - 1)
                        Expanded(
                          child: Container(
                            width: lineWidth,
                            color: colors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      bottom: i < items.length - 1 ? itemSpacing : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                items[i].title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            if (items[i].timestamp != null)
                              Text(
                                items[i].timestamp!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                          ],
                        ),
                        if (items[i].subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            items[i].subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (items[i].content != null) ...[
                          const SizedBox(height: 8),
                          items[i].content!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, this.icon});

  final double size;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: icon == null
          ? null
          : Icon(icon, size: size * 0.6, color: Colors.white),
    );
  }
}
