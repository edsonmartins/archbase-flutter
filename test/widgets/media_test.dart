import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseSwipeToConfirm', () {
    testWidgets('renderiza label inicial', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 300,
            child: ArchbaseSwipeToConfirm(
              label: 'Arraste para confirmar',
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.text('Arraste para confirmar'), findsOneWidget);
    });

    testWidgets('icon customizado é renderizado', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 300,
            child: ArchbaseSwipeToConfirm(
              label: 'Arraste',
              icon: Icons.delete,
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('cor customizada é aplicada ao container', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 300,
            child: ArchbaseSwipeToConfirm(
              label: 'Arraste',
              color: Colors.red,
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.byType(ArchbaseSwipeToConfirm), findsOneWidget);
      // O widget renderiza sem erros com a cor custom (smoke).
    });
  });

  group('ArchbaseSignaturePad', () {
    testWidgets('renderiza placeholder, limpar e confirmar', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 400,
            height: 320,
            child: ArchbaseSignaturePad(),
          ),
        ),
      );
      expect(find.text('Assine no espaço acima'), findsOneWidget);
      expect(find.text('Limpar'), findsOneWidget);
      expect(find.text('Confirmar assinatura'), findsOneWidget);
    });

    testWidgets('labels customizadas são exibidas', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: SizedBox(
            width: 400,
            height: 320,
            child: ArchbaseSignaturePad(
              clearLabel: 'Reset',
              confirmLabel: 'OK',
              placeholder: 'Assine aqui',
            ),
          ),
        ),
      );
      expect(find.text('Assine aqui'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('sem assinatura, confirmar não dispara onConfirm',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: 400,
            height: 320,
            child: ArchbaseSignaturePad(
              onConfirm: (_) => calls++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirmar assinatura'));
      await tester.pump();
      expect(calls, 0);
    });
  });
}
