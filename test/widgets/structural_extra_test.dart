import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseStickyHeader', () {
    testWidgets('renderiza header e child', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            height: 600,
            child: ArchbaseStickyHeader(
              header: ColoredBox(color: Colors.blue, child: Text('cabecalho')),
              child: SizedBox(height: 1200, child: Text('body')),
            ),
          ),
        ),
      );
      expect(find.text('cabecalho'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('ArchbaseStickyHeaderDelegate respeita minExtent/maxExtent',
        (tester) async {
      final delegate = ArchbaseStickyHeaderDelegate(
        child: const Text('h'),
        height: 80,
      );
      expect(delegate.minExtent, 80);
      expect(delegate.maxExtent, 80);
      expect(delegate.shouldRebuild(delegate), isTrue);
    });
  });

  group('ArchbaseClippers', () {
    test('WaveClipper reclipa quando amplitude muda', () {
      final a = ArchbaseWaveClipper(amplitude: 24);
      final b = ArchbaseWaveClipper(amplitude: 48);
      expect(a.shouldReclip(b), isTrue);
      expect(a.shouldReclip(ArchbaseWaveClipper(amplitude: 24)), isFalse);
    });

    test('ArcClipper reclipa quando depth muda', () {
      final a = ArchbaseArcClipper(depth: 30);
      expect(a.shouldReclip(ArchbaseArcClipper(depth: 60)), isTrue);
      expect(a.shouldReclip(ArchbaseArcClipper(depth: 30)), isFalse);
    });

    test('DiagonalClipper reclipa quando slope/fromLeft muda', () {
      final a = ArchbaseDiagonalClipper(slope: 60, fromLeft: true);
      expect(a.shouldReclip(ArchbaseDiagonalClipper(slope: 80)), isTrue);
      expect(
        a.shouldReclip(ArchbaseDiagonalClipper(slope: 60, fromLeft: false)),
        isTrue,
      );
      expect(
        a.shouldReclip(ArchbaseDiagonalClipper(slope: 60, fromLeft: true)),
        isFalse,
      );
    });

    test('getClip retorna Path não-vazio para os 3 clippers', () {
      const size = Size(400, 200);
      expect(ArchbaseWaveClipper().getClip(size).getBounds().isEmpty, isFalse);
      expect(ArchbaseArcClipper().getClip(size).getBounds().isEmpty, isFalse);
      expect(
        ArchbaseDiagonalClipper().getClip(size).getBounds().isEmpty,
        isFalse,
      );
    });

    testWidgets('ArchbaseClippedHeader aplica ClipPath em volta do child',
        (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseClippedHeader(
            color: Colors.blue,
            height: 120,
            child: Center(child: Text('header')),
          ),
        ),
      );
      expect(find.text('header'), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
    });
  });
}
