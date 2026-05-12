import 'package:flutter/material.dart';

/// Legenda compartilhada por Line/Bar/Pie/Area charts.
class ArchbaseChartLegend extends StatelessWidget {
  const ArchbaseChartLegend({
    super.key,
    required this.items,
    this.itemSpacing = 12,
    this.dotSize = 10,
    this.compact = false,
  });

  /// Lista de `(rótulo, cor)` para cada item da legenda.
  final List<({String label, Color color})> items;
  final double itemSpacing;
  final double dotSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;
    return Wrap(
      spacing: itemSpacing,
      runSpacing: 6,
      children: items
          .map(
            (it) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: it.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(it.label, style: textStyle),
              ],
            ),
          )
          .toList(),
    );
  }
}
