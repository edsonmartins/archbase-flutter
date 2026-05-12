import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../feedback/archbase_empty_state.dart';
import 'archbase_chart_data.dart';
import 'archbase_chart_legend.dart';

/// Pie chart (ou donut, se [donut] = true).
///
/// O `value` de cada slice é absoluto — o chart normaliza para 100%.
/// Use [centerText] para exibir o total/valor principal no meio (donut).
class ArchbasePieChart extends StatefulWidget {
  const ArchbasePieChart({
    super.key,
    required this.slices,
    this.title,
    this.subtitle,
    this.size = 220,
    this.donut = false,
    this.centerText,
    this.centerSubtext,
    this.showLegend = true,
    this.showPercent = true,
    this.emptyMessage = 'Sem dados para exibir',
  });

  final List<ArchbaseChartSlice> slices;
  final String? title;
  final String? subtitle;
  final double size;
  final bool donut;
  final String? centerText;
  final String? centerSubtext;
  final bool showLegend;
  final bool showPercent;
  final String emptyMessage;

  @override
  State<ArchbasePieChart> createState() => _ArchbasePieChartState();
}

class _ArchbasePieChartState extends State<ArchbasePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final palette = context.archbaseColors.chartPalette;
    final total = widget.slices.fold<double>(0, (s, x) => s + x.value);
    final hasData = total > 0 && widget.slices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SizedBox(
          height: widget.size,
          child: hasData
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: _buildSections(palette, total),
                        sectionsSpace: 2,
                        centerSpaceRadius:
                            widget.donut ? widget.size * 0.25 : 0,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                      ),
                    ),
                    if (widget.donut && widget.centerText != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.centerText!,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (widget.centerSubtext != null)
                            Text(
                              widget.centerSubtext!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                  ],
                )
              : ArchbaseEmptyState(title: widget.emptyMessage),
        ),
        if (widget.showLegend && hasData) ...[
          const SizedBox(height: 12),
          ArchbaseChartLegend(
            items: [
              for (var i = 0; i < widget.slices.length; i++)
                (
                  label: _legendLabel(i, total),
                  color: widget.slices[i].color ?? palette[i % palette.length],
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _legendLabel(int i, double total) {
    final s = widget.slices[i];
    if (!widget.showPercent) return s.label;
    final pct = total == 0 ? 0.0 : (s.value / total) * 100;
    return '${s.label} (${pct.toStringAsFixed(1)}%)';
  }

  List<PieChartSectionData> _buildSections(List<Color> palette, double total) {
    final result = <PieChartSectionData>[];
    for (var i = 0; i < widget.slices.length; i++) {
      final s = widget.slices[i];
      final isTouched = i == _touchedIndex;
      final radius = widget.size * (isTouched ? 0.42 : 0.38);
      final color = s.color ?? palette[i % palette.length];
      final pct = total == 0 ? 0.0 : (s.value / total) * 100;

      result.add(
        PieChartSectionData(
          color: color,
          value: s.value,
          radius: radius,
          title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: TextStyle(
            color: Colors.white,
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return result;
  }
}
