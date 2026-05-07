import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseTextField', () {
    testWidgets('label com required vira "label *"', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseTextField(label: 'Nome', required: true),
        ),
      );
      expect(find.text('Nome *'), findsOneWidget);
    });

    testWidgets('label sem required permanece igual', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: ArchbaseTextField(label: 'Nome')),
      );
      expect(find.text('Nome'), findsOneWidget);
    });

    testWidgets('validator é chamado em validate', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        TestApp(
          child: Form(
            key: formKey,
            child: const ArchbaseTextField(
              label: 'CPF',
              validator: ArchbaseValidators.cpf,
            ),
          ),
        ),
      );
      expect(formKey.currentState?.validate(), isFalse);
      await tester.pump();
      expect(find.textContaining('CPF inválido'), findsOneWidget);
    });
  });

  group('ArchbasePasswordField', () {
    testWidgets('toggle obscure inverte estado', (tester) async {
      final controller = TextEditingController(text: 'segredo');
      await tester.pumpWidget(
        TestApp(
          child: ArchbasePasswordField(controller: controller),
        ),
      );

      // Inicia ocultando.
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);

      // Toca no ícone de olho.
      await tester.tap(find.byIcon(LucideIcons.eyeOff));
      await tester.pump();

      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
    });
  });

  group('ArchbaseButton', () {
    testWidgets('estado loading mostra spinner em vez do label',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseButton(
            label: 'Salvar',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      expect(find.text('Salvar'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disable quando onPressed é null', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseButton(label: 'Salvar', onPressed: null),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('variante danger usa cor de erro', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseButton(
            label: 'Excluir',
            onPressed: () {},
            variant: ArchbaseButtonVariant.danger,
          ),
        ),
      );
      expect(find.text('Excluir'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('callback dispara em tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseButton(
            label: 'Tap',
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('ArchbaseConfirmDialog', () {
    testWidgets('confirmar pop devolve true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ArchbaseConfirmDialog.show(
                  context,
                  title: 'Sair?',
                  message: 'Tem certeza?',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Sair?'), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancelar pop devolve false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ArchbaseConfirmDialog.show(
                  context,
                  title: 'Sair?',
                  message: 'Tem certeza?',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
