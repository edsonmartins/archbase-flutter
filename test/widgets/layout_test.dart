import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseAppBar', () {
    testWidgets('renderiza title e subtitle', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: Scaffold(
            appBar: ArchbaseAppBar(title: 'Visitas', subtitle: '12 hoje'),
            body: SizedBox.shrink(),
          ),
        ),
      );
      expect(find.text('Visitas'), findsOneWidget);
      expect(find.text('12 hoje'), findsOneWidget);
    });

    testWidgets('actions são exibidas', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            appBar: ArchbaseAppBar(
              title: 'Lista',
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets(
        'sem Navigator.canPop, não renderiza back button (mesmo com showBackButton=true)',
        (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: Scaffold(
            appBar: ArchbaseAppBar(title: 'Home'),
            body: SizedBox.shrink(),
          ),
        ),
      );
      // Home da MaterialApp não tem rota anterior — back ausente.
      expect(find.byType(BackButtonIcon), findsNothing);
    });
  });

  group('ArchbaseCard', () {
    testWidgets('renderiza title, subtitle e body', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseCard(
            title: 'Cliente X',
            subtitle: 'Rua A, 123',
            body: Text('detalhes'),
          ),
        ),
      );
      expect(find.text('Cliente X'), findsOneWidget);
      expect(find.text('Rua A, 123'), findsOneWidget);
      expect(find.text('detalhes'), findsOneWidget);
    });

    testWidgets('status renderiza chip com label', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseCard(
            title: 'Cliente X',
            status: ArchbaseCardStatus(
              color: Colors.green,
              label: 'Ativo',
              icon: Icons.check_circle,
            ),
          ),
        ),
      );
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('onTap dispara callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCard(
            title: 'Tap me',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });
  });

  group('ArchbaseScaffold', () {
    testWidgets('sem connectivity/queue, não renderiza banner', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseScaffold(
            body: Text('conteudo'),
          ),
        ),
      );
      expect(find.text('conteudo'), findsOneWidget);
      // Sem syncQueue/connectivity, o banner não é instanciado.
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('com onRefresh, envolve em RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseScaffold(
            body: ListView(
              children: const [SizedBox(height: 600, child: Text('conteudo'))],
            ),
            onRefresh: () async {},
          ),
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('ArchbaseSectionHeader', () {
    testWidgets('renderiza title e subtitle', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseSectionHeader(
            title: 'Conta',
            subtitle: 'Dados pessoais',
          ),
        ),
      );
      expect(find.text('Conta'), findsOneWidget);
      expect(find.text('Dados pessoais'), findsOneWidget);
    });

    testWidgets('icon é renderizado quando informado', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseSectionHeader(
            title: 'Conta',
            icon: Icons.person,
          ),
        ),
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('action é renderizada à direita', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSectionHeader(
            title: 'Endereços',
            action: TextButton(onPressed: () {}, child: const Text('Ver tudo')),
          ),
        ),
      );
      expect(find.text('Ver tudo'), findsOneWidget);
    });
  });
}
