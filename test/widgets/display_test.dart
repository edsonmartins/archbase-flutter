import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseBadgeAdv', () {
    testWidgets('renderiza o child e o label do badge', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseBadgeAdv(
            label: '3',
            child: Icon(Icons.notifications, size: 32),
          ),
        ),
      );
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('show=false oculta o badge mas mantém o child', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseBadgeAdv(
            label: '9',
            show: false,
            child: Icon(Icons.notifications, size: 32),
          ),
        ),
      );
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('modo dot não renderiza label', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseBadgeAdv(
            label: 'ignorado',
            dot: true,
            child: Icon(Icons.mail, size: 32),
          ),
        ),
      );
      expect(find.byIcon(Icons.mail), findsOneWidget);
      expect(find.text('ignorado'), findsNothing);
    });
  });

  group('ArchbaseCarousel', () {
    testWidgets('renderiza item inicial', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 400,
            child: ArchbaseCarousel(
              height: 120,
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                color: Colors.blue,
                child: Center(child: Text('slide-$i')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('slide-0'), findsOneWidget);
    });

    testWidgets('showIndicators=false omite os dots', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 400,
            child: ArchbaseCarousel(
              height: 120,
              itemCount: 3,
              showIndicators: false,
              itemBuilder: (_, i) => Text('slide-$i'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('onPageChanged é disparado ao trocar página', (tester) async {
      int? lastIndex;
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 400,
            child: ArchbaseCarousel(
              height: 120,
              itemCount: 3,
              loop: false,
              onPageChanged: (i) => lastIndex = i,
              itemBuilder: (_, i) => Text('slide-$i'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag horizontalmente para a esquerda → próxima página.
      await tester.drag(
        find.byType(PageView),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(lastIndex, isNotNull);
      expect(lastIndex! >= 1, isTrue);
    });
  });
}
