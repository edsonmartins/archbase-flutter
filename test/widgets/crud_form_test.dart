import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        theme: ArchbaseTheme.light(),
        home: child,
      );

  group('ArchbaseCrudFormScreen', () {
    testWidgets('renderiza title e botão Salvar', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseCrudFormScreen(
            title: 'Cliente',
            formBuilder: (_, __) => const ArchbaseTextField(label: 'Nome'),
            onSubmit: () async => null,
          ),
        ),
      );
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('validação bloqueia submit e onSubmit não é chamado',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          ArchbaseCrudFormScreen(
            title: 'Cliente',
            formBuilder: (_, __) => const ArchbaseTextField(
              label: 'Nome',
              required: true,
              validator: ArchbaseValidators.required,
            ),
            onSubmit: () async {
              calls++;
              return null;
            },
          ),
        ),
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('submit válido fecha a tela com true', (tester) async {
      Object? popResult;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => ArchbaseCrudFormScreen(
                        title: 'Cliente',
                        formBuilder: (_, __) =>
                            const ArchbaseTextField(label: 'Nome'),
                        onSubmit: () async => null,
                        confirmDiscardOnPop: false,
                      ),
                    ),
                  );
                },
                child: const Text('abrir form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir form'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(popResult, true);
    });

    testWidgets('submit com erro exibe AlertDialog e não fecha',
        (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseCrudFormScreen(
            title: 'Cliente',
            formBuilder: (_, __) => const ArchbaseTextField(label: 'Nome'),
            onSubmit: () async => 'Servidor indisponível',
          ),
        ),
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível salvar'), findsOneWidget);
      expect(find.text('Servidor indisponível'), findsOneWidget);
    });

    testWidgets('onDelete pede confirmação; cancelar não chama onDelete',
        (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        app(
          ArchbaseCrudFormScreen(
            title: 'Cliente',
            formBuilder: (_, __) => const ArchbaseTextField(label: 'Nome'),
            onSubmit: () async => null,
            onDelete: () async {
              deleted = true;
              return null;
            },
          ),
        ),
      );
      expect(find.text('Excluir'), findsOneWidget);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      // Confirm dialog aparece (título do dialog).
      expect(find.text('Confirmar exclusão'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
    });

    testWidgets('onDelete confirmado dispara callback', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        app(
          ArchbaseCrudFormScreen(
            title: 'Cliente',
            formBuilder: (_, __) => const ArchbaseTextField(label: 'Nome'),
            onSubmit: () async => null,
            onDelete: () async {
              deleted = true;
              return null;
            },
          ),
        ),
      );
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      // Botão de confirmação do dialog.
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('confirmDiscardOnPop pede confirmação quando há dirty',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: ArchbaseTheme.light(),
          navigatorKey: navKey,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => ArchbaseCrudFormScreen(
                      title: 'Cliente',
                      formBuilder: (_, __) =>
                          const ArchbaseTextField(label: 'Nome'),
                      onSubmit: () async => null,
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Dirty o form.
      await tester.enterText(find.byType(TextField), 'João');
      await tester.pump();

      // Tenta voltar.
      navKey.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);
    });
  });
}
