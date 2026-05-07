import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseLoginScreen', () {
    testWidgets('chama onLogin com username/password ao tocar Entrar',
        (tester) async {
      String? receivedUser;
      String? receivedPwd;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseLoginScreen(
            appName: 'Demo',
            onLogin: (u, p, _) async {
              receivedUser = u;
              receivedPwd = p;
              return null;
            },
          ),
        ),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail *'), 'edson@x.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha *'), 'minhasenha');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(receivedUser, 'edson@x.com');
      expect(receivedPwd, 'minhasenha');
    });

    testWidgets('exibe erro retornado por onLogin', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseLoginScreen(
            onLogin: (_, __, ___) async => 'Credenciais inválidas',
          ),
        ),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail *'), 'a@b.co');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha *'), 'x');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Credenciais inválidas'), findsOneWidget);
    });

    testWidgets('campos vazios dispara mensagem de obrigatório', (tester) async {
      var called = false;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseLoginScreen(
            onLogin: (_, __, ___) async {
              called = true;
              return null;
            },
          ),
        ),
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
      expect(find.text('Campo obrigatório'), findsWidgets);
    });

    testWidgets('mostra "Esqueci minha senha" quando callback existe',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseLoginScreen(
            onLogin: (_, __, ___) async => null,
            onForgotPassword: () {},
          ),
        ),
      );
      expect(find.text('Esqueci minha senha'), findsOneWidget);
    });
  });
}
