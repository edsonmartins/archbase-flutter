import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../feedback/archbase_empty_state.dart';
import 'archbase_chart_data.dart';
import 'archbase_chart_legend.dart';

/// Area chart — variante de LineChart com preenchimento embaixo da
/// linha. Útil para volume/tendência ao longo do tempo.
class ArchbaseAreaChart extends StatelessWidget {
  const ArchbaseAreaChart({
    super.key,
    required this.series,
    this.title,
    this.subtitle,
    this.height = 280,
    this.showLegend = true,
    this.curved = true,
    this.minY,
    this.maxY,
    this.areaOpacity = 0.25,
    this.xLabelFormatter,
    this.yLabelFormatter,
    this.emptyMessage = 'Sem dados para exibir',
  });

  final List<ArchbaseChartSeries> series;
  final String? title;
  final String? subtitle;
  final double height;
  final bool showLegend;
  final bool curved;
  final double? minY;
  final double? maxY;
  final double areaOpacity;
  final String Function(double value)? xLabelFormatter;
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
              ? LineChart(
                  LineChartData(
                    lineBarsData: [
                      for (var i = 0; i < series.length; i++)
                        if (series[i].points.isNotEmpty)
                          LineChartBarData(
                            spots: series[i]
                                .points
                                .map((p) => FlSpot(p.x, p.y))
                                .toList(),
                            color:
                                series[i].color ?? palette[i % palette.length],
                            isCurved: curved,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (series[i].color ??
                                      palette[i % palette.length])
                                  .withValues(alpha: areaOpacity),
                            ),
                          ),
                    ],
                    minY: minY,
                    maxY: maxY,
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
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            yLabelFormatter?.call(value) ??
                                value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, meta) => Text(
                            xLabelFormatter?.call(value) ??
                                value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
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
}
