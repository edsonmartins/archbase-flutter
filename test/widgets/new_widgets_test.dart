import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseTextAvatar', () {
    testWidgets('exibe iniciais geradas a partir do texto', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: ArchbaseTextAvatar(text: 'Edson Martins')),
      );
      expect(find.text('EM'), findsOneWidget);
    });

    testWidgets('cor é determinística para o mesmo texto', (tester) async {
      Color? colorA;
      Color? colorB;
      await tester.pumpWidget(const TestApp(
        child: Column(children: [
          ArchbaseTextAvatar(text: 'Hello'),
          ArchbaseTextAvatar(text: 'Hello'),
        ]),
      ));
      final containers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      // Pegar os 2 containers que renderizam o avatar.
      final avatarBgs = containers
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration as BoxDecoration).color)
          .toList();
      if (avatarBgs.length >= 2) {
        colorA = avatarBgs[0];
        colorB = avatarBgs[1];
        expect(colorA, equals(colorB));
      }
    });
  });

  group('ArchbaseAccordion', () {
    testWidgets('toca header expande conteúdo', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseAccordion(
            items: [
              ArchbaseAccordionItem(
                header: 'Seção 1',
                content: Text('Conteúdo 1'),
              ),
              ArchbaseAccordionItem(
                header: 'Seção 2',
                content: Text('Conteúdo 2'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Conteúdo 1'), findsNothing);
      await tester.tap(find.text('Seção 1'));
      await tester.pumpAndSettle();
      expect(find.text('Conteúdo 1'), findsOneWidget);
    });

    testWidgets('singleOpen=true fecha outras ao abrir', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseAccordion(
            singleOpen: true,
            items: [
              ArchbaseAccordionItem(
                header: 'A',
                content: Text('aaa'),
                expanded: true,
              ),
              ArchbaseAccordionItem(
                header: 'B',
                content: Text('bbb'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('aaa'), findsOneWidget);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('aaa'), findsNothing);
      expect(find.text('bbb'), findsOneWidget);
    });
  });

  group('ArchbaseTimeline', () {
    testWidgets('renderiza todos os itens com título', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseTimeline(
            items: [
              ArchbaseTimelineItem(title: 'Início'),
              ArchbaseTimelineItem(title: 'Meio', subtitle: 'detalhe'),
              ArchbaseTimelineItem(title: 'Fim', timestamp: '14:30'),
            ],
          ),
        ),
      );
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Meio'), findsOneWidget);
      expect(find.text('detalhe'), findsOneWidget);
      expect(find.text('Fim'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });
  });

  group('ArchbaseNumericStepper', () {
    testWidgets('botões +/- alteram valor', (tester) async {
      num current = 5;
      await tester.pumpWidget(
        TestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return ArchbaseNumericStepper(
                value: current,
                min: 0,
                max: 10,
                editable: false,
                onChanged: (v) => setState(() => current = v),
              );
            },
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);

      final inkwells = find.byType(InkWell);
      expect(inkwells, findsNWidgets(2));

      await tester.tap(inkwells.last); // +
      await tester.pumpAndSettle();
      expect(current, 6);

      await tester.tap(inkwells.first); // -
      await tester.pumpAndSettle();
      expect(current, 5);

      await tester.tap(inkwells.first); // -
      await tester.pumpAndSettle();
      expect(current, 4);
    });

    testWidgets('respeita min', (tester) async {
      num current = 0;
      await tester.pumpWidget(
        TestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return ArchbaseNumericStepper(
                value: current,
                min: 0,
                max: 5,
                editable: false,
                onChanged: (v) => setState(() => current = v),
              );
            },
          ),
        ),
      );
      final inkwells = find.byType(InkWell);
      await tester.tap(inkwells.first);
      await tester.pumpAndSettle();
      expect(current, 0);
    });
  });

  group('ArchbaseGlassContainer', () {
    testWidgets('renderiza o filho dentro do efeito', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseGlassContainer(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('glass!'),
            ),
          ),
        ),
      );
      expect(find.text('glass!'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('ArchbaseFloatingNavBar', () {
    testWidgets('toca em item dispara onTap com índice', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseFloatingNavBar(
            currentIndex: 0,
            onTap: (i) => tappedIndex = i,
            items: const [
              ArchbaseFloatingNavBarItem(icon: Icons.home, label: 'Home'),
              ArchbaseFloatingNavBarItem(icon: Icons.search, label: 'Buscar'),
              ArchbaseFloatingNavBarItem(icon: Icons.person, label: 'Perfil'),
            ],
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      expect(tappedIndex, 1);
    });
  });

  group('ArchbaseForm', () {
    testWidgets('controller agrega valores dos campos', (tester) async {
      final controller = ArchbaseFormController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseForm(
            controller: controller,
            child: const Column(
              children: [
                ArchbaseFormTextField(name: 'nome', label: 'Nome'),
                ArchbaseFormCpfField(name: 'cpf', required: false),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Edson',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF'),
        '529.982.247-25',
      );
      await tester.pump();

      expect(controller.read<String>('nome'), 'Edson');
      expect(controller.read<String>('cpf'), '529.982.247-25');
    });

    testWidgets('initialValues preenche os campos', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseForm(
            initialValues: {'email': 'edson@archbase.dev'},
            child: ArchbaseFormEmailField(name: 'email'),
          ),
        ),
      );
      expect(find.text('edson@archbase.dev'), findsOneWidget);
    });
  });
}
