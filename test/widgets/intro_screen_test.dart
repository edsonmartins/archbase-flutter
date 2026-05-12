import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        theme: ArchbaseTheme.light(),
        home: child,
      );

  const pages = [
    ArchbaseIntroPage(
      title: 'Bem-vindo',
      description: 'Sua primeira tela',
      icon: Icons.star,
    ),
    ArchbaseIntroPage(
      title: 'Recursos',
      description: 'O que você pode fazer',
      icon: Icons.dashboard,
    ),
    ArchbaseIntroPage(
      title: 'Pronto',
      description: 'Vamos lá',
      icon: Icons.check,
    ),
  ];

  group('ArchbaseIntroScreen', () {
    testWidgets('renderiza primeira página e botões iniciais', (tester) async {
      await tester.pumpWidget(
        app(ArchbaseIntroScreen(pages: pages, onDone: () {})),
      );
      expect(find.text('Bem-vindo'), findsOneWidget);
      expect(find.text('Sua primeira tela'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('skip dispara onSkip quando informado', (tester) async {
      var skipped = false;
      await tester.pumpWidget(
        app(
          ArchbaseIntroScreen(
            pages: pages,
            onDone: () {},
            onSkip: () => skipped = true,
          ),
        ),
      );
      await tester.tap(find.text('Pular'));
      await tester.pump();
      expect(skipped, isTrue);
    });

    testWidgets('skip cai em onDone se onSkip não for informado',
        (tester) async {
      var done = false;
      await tester.pumpWidget(
        app(ArchbaseIntroScreen(pages: pages, onDone: () => done = true)),
      );
      await tester.tap(find.text('Pular'));
      await tester.pump();
      expect(done, isTrue);
    });

    testWidgets('next avança e na última página vira "Começar"',
        (tester) async {
      var done = false;
      await tester.pumpWidget(
        app(ArchbaseIntroScreen(pages: pages, onDone: () => done = true)),
      );

      // Avança 2x via botão "Próximo"
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Última página: label muda para "Começar" e skip some.
      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);

      await tester.tap(find.text('Começar'));
      await tester.pump();
      expect(done, isTrue);
    });

    testWidgets('showSkip=false não renderiza skip', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseIntroScreen(
            pages: pages,
            onDone: () {},
            showSkip: false,
          ),
        ),
      );
      expect(find.text('Pular'), findsNothing);
    });

    testWidgets('labels customizados são exibidos', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseIntroScreen(
            pages: pages,
            onDone: () {},
            skipLabel: 'Skip',
            nextLabel: 'Next',
            doneLabel: 'Start',
          ),
        ),
      );
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });
}
