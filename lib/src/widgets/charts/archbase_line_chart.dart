import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../feedback/archbase_empty_state.dart';
import 'archbase_chart_data.dart';
import 'archbase_chart_legend.dart';

/// Line chart opinado da archbase. Aceita múltiplas séries, ajusta
/// eixos automaticamente e usa a `chartPalette` do tema.
class ArchbaseLineChart extends StatelessWidget {
  const ArchbaseLineChart({
    super.key,
    required this.series,
    this.title,
    this.subtitle,
    this.height = 280,
    this.showLegend = true,
    this.showDots = false,
    this.curved = true,
    this.minY,
    this.maxY,
    this.xAxisLabel,
    this.yAxisLabel,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.emptyMessage = 'Sem dados para exibir',
  });

  final List<ArchbaseChartSeries> series;
  final String? title;
  final String? subtitle;
  final double height;
  final bool showLegend;
  final bool showDots;
  final bool curved;
  final double? minY;
  final double? maxY;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final String Function(double value)? xLabelFormatter;
  final String Function(double value)? yLabelFormatter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final palette = context.archbaseColors.chartPalette;
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
              ? LineChart(
                  _buildData(palette, context),
                  duration: const Duration(milliseconds: 350),
                )
              : ArchbaseEmptyState(title: emptyMessage),
        ),
        if (showLegend && hasData) ...[
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

  LineChartData _buildData(List<Color> palette, BuildContext context) {
    final colors = context.archbase;
    final lines = <LineChartBarData>[];

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (s.points.isEmpty) continue;
      final c = s.color ?? palette[i % palette.length];
      lines.add(
        LineChartBarData(
          spots: s.points.map((p) => FlSpot(p.x, p.y)).toList(),
          color: c,
          isCurved: curved,
          barWidth: 2.5,
          dotData: FlDotData(show: showDots),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );
    }

    return LineChartData(
      lineBarsData: lines,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.border,
          strokeWidth: 1,
        ),
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
          axisNameWidget: yAxisLabel == null ? null : Text(yAxisLabel!),
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
          axisNameWidget: xAxisLabel == null ? null : Text(xAxisLabel!),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (value, meta) => Text(
              xLabelFormatter?.call(value) ?? value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => colors.textPrimary.withValues(alpha: 0.9),
          getTooltipItems: (spots) => spots.map((s) {
            final name = series[s.barIndex].name;
            return LineTooltipItem(
              '$name\n${yLabelFormatter?.call(s.y) ?? s.y.toStringAsFixed(2)}',
              TextStyle(
                color: colors.background,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
