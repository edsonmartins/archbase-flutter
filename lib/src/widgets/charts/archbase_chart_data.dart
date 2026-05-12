import 'package:flutter/material.dart';

/// Um ponto (x, y) em qualquer chart cartesiano.
class ArchbaseChartPoint {
  const ArchbaseChartPoint(this.x, this.y);
  final double x;
  final double y;
}

/// Uma série de pontos com nome e cor opcional. Se [color] for null,
/// o chart escolhe da `ArchbaseColors.chartPalette` pelo índice.
class ArchbaseChartSeries {
  const ArchbaseChartSeries({
    required this.name,
    required this.points,
    this.color,
  });

  final String name;
  final List<ArchbaseChartPoint> points;
  final Color? color;
}

/// Slice de pie/donut: rótulo + valor (não-normalizado; o chart normaliza
/// para 100%).
class ArchbaseChartSlice {
  const ArchbaseChartSlice({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}
