import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../feedback/archbase_empty_state.dart';
import 'archbase_chart_data.dart';
import 'archbase_chart_legend.dart';

/// Bar chart vertical. Aceita uma ou mais séries (barras agrupadas
/// lado a lado quando há múltiplas séries por categoria).
///
/// Use [labels] para nomear o eixo X (mesmo length de `points` de cada série).
class ArchbaseBarChart extends StatelessWidget {
  const ArchbaseBarChart({
    super.key,
    required this.series,
    required this.labels,
    this.title,
    this.subtitle,
    this.height = 280,
    this.showLegend = true,
    this.yLabelFormatter,
    this.emptyMessage = 'Sem dados para exibir',
  })  : assert(series.length > 0, 'Forneça pelo menos uma série'),
        assert(labels.length > 0, 'Forneça labels do eixo X');

  final List<ArchbaseChartSeries> series;
  final List<String> labels;
  final String? title;
  final String? subtitle;
  final double height;
  final bool showLegend;
  final String Function(double value)? yLabelFormatter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final palette = context.archbaseColors.chartPalette;
    final colors = context.archbase;
    final hasData = series.any((s) => s.points.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SizedBox(
          height: height,
          child: hasData
              ? BarChart(
                  _buildData(palette, colors, context),
                  duration: const Duration(milliseconds: 350),
                )
              : ArchbaseEmptyState(title: emptyMessage),
        ),
        if (showLegend && hasData && series.length > 1) ...[
          const SizedBox(height: 12),
          ArchbaseChartLegend(
            items: [
              for (var i = 0; i < series.length; i++)
                (
                  label: series[i].name,
                  color: series[i].color ?? palette[i % palette.length],
                ),
            ],
          ),
        ],
      ],
    );
  }

  BarChartData _buildData(
    List<Color> palette,
    dynamic colors,
    BuildContext context,
  ) {
    final groups = <BarChartGroupData>[];
    for (var x = 0; x < labels.length; x++) {
      final rods = <BarChartRodData>[];
      for (var i = 0; i < series.length; i++) {
        final point = series[i].points.length > x ? series[i].points[x] : null;
        final color = series[i].color ?? palette[i % palette.length];
        rods.add(
          BarChartRodData(
            toY: point?.y ?? 0,
            color: color,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }
      groups.add(BarChartGroupData(x: x, barRods: rods, barsSpace: 4));
    }

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: colors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              yLabelFormatter?.call(value) ?? value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= labels.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  labels[idx],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => colors.textPrimary.withValues(alpha: 0.9),
          getTooltipItem: (group, groupIdx, rod, rodIdx) {
            final name = series[rodIdx].name;
            return BarTooltipItem(
              '$name: ${yLabelFormatter?.call(rod.toY) ?? rod.toY.toStringAsFixed(2)}',
              TextStyle(
                color: colors.background,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}
