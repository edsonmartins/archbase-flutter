import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        theme: ArchbaseTheme.light(),
        home: child,
      );

  List<ArchbaseDetailSection> sections() => [
        ArchbaseDetailSection(
          title: 'Dados',
          icon: Icons.info,
          builder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('conteudo-dados'),
          ),
        ),
        ArchbaseDetailSection(
          title: 'Histórico',
          icon: Icons.history,
          builder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('conteudo-historico'),
          ),
        ),
      ];

  group('ArchbaseDetailScreen', () {
    testWidgets('modo seções verticais (default) lista todos os builders',
        (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseDetailScreen(
            title: 'Cliente',
            subtitle: 'Detalhes',
            sections: sections(),
          ),
        ),
      );
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('Dados'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
      expect(find.text('conteudo-dados'), findsOneWidget);
      expect(find.text('conteudo-historico'), findsOneWidget);
    });

    testWidgets('header é renderizado antes das seções', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseDetailScreen(
            title: 'Cliente',
            header: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('header-custom'),
            ),
            sections: sections(),
          ),
        ),
      );
      expect(find.text('header-custom'), findsOneWidget);
    });

    testWidgets('useTabs=true renderiza TabBar e troca conteúdo',
        (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseDetailScreen(
            title: 'Cliente',
            useTabs: true,
            sections: sections(),
          ),
        ),
      );
      expect(find.byType(TabBar), findsOneWidget);
      // Primeira aba: conteúdo-dados visível
      expect(find.text('conteudo-dados'), findsOneWidget);

      // Troca para a aba "Histórico"
      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(find.text('conteudo-historico'), findsOneWidget);
    });

    testWidgets('bottomActions são exibidas', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        app(
          ArchbaseDetailScreen(
            title: 'Cliente',
            sections: sections(),
            bottomActions: [
              ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Confirmar'), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      expect(tapped, isTrue);
    });

    testWidgets('appBarActions aparecem no AppBar', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseDetailScreen(
            title: 'Cliente',
            sections: sections(),
            appBarActions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
