import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseLoading', () {
    testWidgets('renderiza spinner sem label', (tester) async {
      await tester.pumpWidget(const TestApp(child: ArchbaseLoading()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('exibe label quando informado', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: ArchbaseLoading(label: 'Carregando dados…')),
      );
      expect(find.text('Carregando dados…'), findsOneWidget);
    });
  });

  group('ArchbaseEmptyState', () {
    testWidgets('mostra título e mensagem', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseEmptyState(
            title: 'Nada por aqui',
            message: 'Cadastre o primeiro item',
          ),
        ),
      );
      expect(find.text('Nada por aqui'), findsOneWidget);
      expect(find.text('Cadastre o primeiro item'), findsOneWidget);
    });

    testWidgets('botão de ação dispara callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseEmptyState(
            title: 'Vazio',
            actionLabel: 'Criar',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('Criar'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('ArchbaseErrorView', () {
    testWidgets('mostra mensagem e botão de retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseErrorView(
            message: 'Falha ao carregar',
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Falha ao carregar'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('versão compact exibe layout em linha', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          child: ArchbaseErrorView(
            message: 'Erro inline',
            compact: true,
          ),
        ),
      );
      expect(find.text('Erro inline'), findsOneWidget);
    });
  });
}
