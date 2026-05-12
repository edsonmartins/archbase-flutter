import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseAlertDialog', () {
    Future<void> openAlert(
      WidgetTester tester, {
      ArchbaseAlertSeverity severity = ArchbaseAlertSeverity.info,
      String title = 'Aviso',
      String message = 'Mensagem do alerta',
      String actionLabel = 'OK',
    }) async {
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ArchbaseAlertDialog.show(
                context,
                title: title,
                message: message,
                severity: severity,
                actionLabel: actionLabel,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('exibe título, mensagem e botão', (tester) async {
      await openAlert(tester, title: 'Tudo certo', message: 'Salvo!');
      expect(find.text('Tudo certo'), findsOneWidget);
      expect(find.text('Salvo!'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('botão fecha o dialog', (tester) async {
      await openAlert(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cada severity instancia o dialog', (tester) async {
      for (final s in ArchbaseAlertSeverity.values) {
        await openAlert(tester, severity: s, title: 'sev-${s.name}');
        expect(find.text('sev-${s.name}'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('actionLabel customizado é renderizado', (tester) async {
      await openAlert(tester, actionLabel: 'Entendi');
      expect(find.text('Entendi'), findsOneWidget);
      expect(find.text('OK'), findsNothing);
    });
  });

  group('ArchbaseBottomSheet', () {
    testWidgets('exibe título e conteúdo', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ArchbaseBottomSheet.show<void>(
                context,
                title: 'Filtros',
                child: const Text('conteúdo do sheet'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('conteúdo do sheet'), findsOneWidget);
    });

    testWidgets('botão de fechar dispensa o sheet', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ArchbaseBottomSheet.show<void>(
                context,
                title: 'Filtros',
                child: const SizedBox.shrink(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(ArchbaseBottomSheet), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(ArchbaseBottomSheet), findsNothing);
    });

    testWidgets('actions são renderizadas', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ArchbaseBottomSheet.show<String>(
                context,
                title: 'Confirme a ação',
                child: const Text('body'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('ok'),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });
  });

  group('ArchbaseToast', () {
    testWidgets('show emite SnackBar com a mensagem', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ArchbaseTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ArchbaseToast.show(
                  context,
                  message: 'Salvo com sucesso',
                  severity: ArchbaseAlertSeverity.success,
                ),
                child: const Text('toast'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('toast'));
      await tester.pump();
      expect(find.text('Salvo com sucesso'), findsOneWidget);
    });
  });
}
