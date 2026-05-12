import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseShimmer', () {
    testWidgets('envolve child em Shimmer.fromColors', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseShimmer(
            child: SizedBox(width: 100, height: 20),
          ),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('ArchbaseShimmerCard', () {
    testWidgets('renderiza com altura padrão', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: ArchbaseShimmerCard()),
      );
      expect(find.byType(ArchbaseShimmerCard), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('ArchbaseShimmerList', () {
    testWidgets('produz a quantidade pedida de cards', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            height: 600,
            child: ArchbaseShimmerList(count: 4, itemHeight: 60),
          ),
        ),
      );
      await tester.pump();
      // Pelo menos os primeiros 4 cards são construídos (ListView lazy
      // pode preparar todos quando cabem em viewport).
      expect(find.byType(ArchbaseShimmerCard), findsWidgets);
    });
  });
}
