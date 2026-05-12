import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

enum _Status with LabeledEnum {
  active('A', 'Ativo'),
  inactive('I', 'Inativo');

  const _Status(this.value, this.label);
  @override
  final String value;
  @override
  final String label;
}

void main() {
  group('ArchbaseDropdown', () {
    testWidgets('renderiza label e value inicial', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseDropdown<String>(
            label: 'Categoria',
            items: const ['a', 'b', 'c'],
            value: 'b',
            itemLabel: (e) => 'Item $e',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Categoria'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);
    });

    testWidgets('label com required vira "label *"', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseDropdown<String>(
            label: 'Categoria',
            required: true,
            items: const ['a'],
            value: 'a',
            itemLabel: (e) => e,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Categoria *'), findsOneWidget);
    });

    testWidgets('abrir lista e selecionar dispara onChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseDropdown<String>(
            items: const ['a', 'b'],
            value: 'a',
            itemLabel: (e) => 'Item $e',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.byType(ArchbaseDropdown<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item b').last);
      await tester.pumpAndSettle();
      expect(selected, 'b');
    });

    testWidgets('forEnum usa o label do LabeledEnum', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseDropdown.forEnum<_Status>(
            label: 'Situação',
            values: _Status.values,
            value: _Status.active,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Ativo'), findsOneWidget);
    });
  });

  group('ArchbaseSearchField', () {
    testWidgets('hint padrão "Buscar…" é exibido', (tester) async {
      await tester.pumpWidget(
        TestApp(child: ArchbaseSearchField(onChanged: (_) {})),
      );
      expect(find.text('Buscar…'), findsOneWidget);
    });

    testWidgets('debounce: dispara somente após o intervalo', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSearchField(
            debounce: const Duration(milliseconds: 200),
            onChanged: values.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'arc');
      await tester.pump(const Duration(milliseconds: 100));
      expect(values, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));
      expect(values, ['arc']);
    });

    testWidgets('com texto, suffix exibe X que limpa o campo', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSearchField(
            controller: controller,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'foo');
      await tester.pump();
      expect(controller.text, 'foo');

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(controller.text, isEmpty);
    });
  });

  group('ArchbaseCountryPicker', () {
    testWidgets('exibe bandeira, nome e dial code', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCountryPicker(
            value: ArchbaseCountries.byCode('BR'),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Brasil'), findsOneWidget);
      expect(find.text('+55'), findsOneWidget);
    });

    testWidgets('showFlag/showDialCode=false ocultam elementos',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCountryPicker(
            value: ArchbaseCountries.byCode('BR'),
            onChanged: (_) {},
            showFlag: false,
            showDialCode: false,
          ),
        ),
      );
      expect(find.text('Brasil'), findsOneWidget);
      expect(find.text('+55'), findsNothing);
    });

    testWidgets('abrir picker exibe lista de países', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCountryPicker(
            value: ArchbaseCountries.byCode('BR'),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Buscar país…'), findsOneWidget);
      expect(find.text('Argentina'), findsOneWidget);
    });

    testWidgets('selecionar país dispara onChanged e fecha sheet',
        (tester) async {
      ArchbaseCountry? selected;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCountryPicker(
            value: ArchbaseCountries.byCode('BR'),
            onChanged: (c) => selected = c,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Argentina'));
      await tester.pumpAndSettle();
      expect(selected?.code, 'AR');
    });

    testWidgets('byCode("ZZ") retorna primeiro país (fallback)',
        (tester) async {
      final fallback = ArchbaseCountries.byCode('ZZ');
      expect(fallback.code, ArchbaseCountries.common.first.code);
    });
  });
}
