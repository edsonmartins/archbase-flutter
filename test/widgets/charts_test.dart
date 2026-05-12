import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseLineChart', () {
    testWidgets('renderiza com série única', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseLineChart(
            title: 'Vendas',
            series: [
              ArchbaseChartSeries(
                name: 'Total',
                points: [
                  ArchbaseChartPoint(0, 10),
                  ArchbaseChartPoint(1, 20),
                  ArchbaseChartPoint(2, 15),
                  ArchbaseChartPoint(3, 30),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget); // legenda
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('mostra empty state quando todas as séries estão vazias',
        (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseLineChart(
            series: [ArchbaseChartSeries(name: 'X', points: [])],
            emptyMessage: 'Nada',
          ),
        ),
      );
      expect(find.text('Nada'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('legenda lista todas as séries', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseLineChart(
            series: [
              ArchbaseChartSeries(
                name: 'A',
                points: [ArchbaseChartPoint(0, 1)],
              ),
              ArchbaseChartSeries(
                name: 'B',
                points: [ArchbaseChartPoint(0, 2)],
              ),
              ArchbaseChartSeries(
                name: 'C',
                points: [ArchbaseChartPoint(0, 3)],
              ),
            ],
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });

  group('ArchbasePieChart', () {
    testWidgets('renderiza slices com legenda %', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbasePieChart(
            slices: [
              ArchbaseChartSlice(label: 'Concluídas', value: 60),
              ArchbaseChartSlice(label: 'Pendentes', value: 40),
            ],
          ),
        ),
      );
      expect(find.byType(PieChart), findsOneWidget);
      // Legenda deve mostrar percentual.
      expect(find.textContaining('Concluídas (60.0%)'), findsOneWidget);
      expect(find.textContaining('Pendentes (40.0%)'), findsOneWidget);
    });

    testWidgets('donut com centerText', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbasePieChart(
            donut: true,
            centerText: 'R\$ 1.500',
            centerSubtext: 'total',
            slices: [
              ArchbaseChartSlice(label: 'A', value: 500),
              ArchbaseChartSlice(label: 'B', value: 1000),
            ],
          ),
        ),
      );
      expect(find.text('R\$ 1.500'), findsOneWidget);
      expect(find.text('total'), findsOneWidget);
    });

    testWidgets('total zero mostra empty state', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbasePieChart(
            slices: [
              ArchbaseChartSlice(label: 'A', value: 0),
            ],
            emptyMessage: 'Sem dados',
          ),
        ),
      );
      expect(find.text('Sem dados'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });
  });

  group('ArchbaseBarChart', () {
    testWidgets('renderiza com labels do eixo X', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseBarChart(
            labels: const ['Jan', 'Fev', 'Mar'],
            series: const [
              ArchbaseChartSeries(
                name: 'Vendas',
                points: [
                  ArchbaseChartPoint(0, 100),
                  ArchbaseChartPoint(1, 150),
                  ArchbaseChartPoint(2, 120),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
    });
  });

  group('ArchbaseAreaChart', () {
    testWidgets('renderiza com fill', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseAreaChart(
            series: [
              ArchbaseChartSeries(
                name: 'Tráfego',
                points: [
                  ArchbaseChartPoint(0, 10),
                  ArchbaseChartPoint(1, 25),
                  ArchbaseChartPoint(2, 15),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
