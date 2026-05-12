import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  tearDown(() {
    // Restaura default pt-BR para não vazar entre testes.
    ArchbaseLocalizations.set(const ArchbaseLocalizationsPtBr());
  });

  group('ArchbaseLocalizations.current', () {
    test('default é pt-BR', () {
      expect(ArchbaseLocalizations.current, isA<ArchbaseLocalizationsPtBr>());
      expect(ArchbaseLocalizations.current.fieldRequired, 'Campo obrigatório');
      expect(ArchbaseLocalizations.current.cpfInvalid, 'CPF inválido');
    });

    test('set substitui o bundle global', () {
      ArchbaseLocalizations.set(const ArchbaseLocalizationsEnUs());
      expect(ArchbaseLocalizations.current, isA<ArchbaseLocalizationsEnUs>());
      expect(ArchbaseLocalizations.current.fieldRequired, 'Required field');
    });
  });

  group('validators usam bundle ativo', () {
    test('em pt-BR retornam mensagens em português', () {
      expect(ArchbaseValidators.required(''), 'Campo obrigatório');
      expect(ArchbaseValidators.cpf('123'), 'CPF inválido');
      expect(ArchbaseValidators.email('xyz'), 'E-mail inválido');
    });

    test('após set EN, mensagens viram em inglês', () {
      ArchbaseLocalizations.set(const ArchbaseLocalizationsEnUs());
      expect(ArchbaseValidators.required(''), 'Required field');
      expect(ArchbaseValidators.cpf('123'), 'Invalid CPF');
      expect(ArchbaseValidators.email('xyz'), 'Invalid e-mail');
    });

    test('parametro message ainda sobrescreve mesmo com locale', () {
      ArchbaseLocalizations.set(const ArchbaseLocalizationsEnUs());
      expect(
        ArchbaseValidators.cpf('123', message: 'Custom message'),
        'Custom message',
      );
    });

    test('minLength usa template do locale ativo', () {
      ArchbaseLocalizations.set(const ArchbaseLocalizationsEnUs());
      expect(ArchbaseValidators.minLength('ab', 5), 'Minimum 5 characters');
    });
  });

  group('ArchbaseLocalizations.of(context)', () {
    testWidgets('sem scope retorna o bundle global', (tester) async {
      ArchbaseLocalizations.set(const ArchbaseLocalizationsEnUs());
      late ArchbaseLocalizations l;
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) {
              l = ArchbaseLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(l, isA<ArchbaseLocalizationsEnUs>());
    });

    testWidgets('com scope usa o bundle fornecido', (tester) async {
      late ArchbaseLocalizations l;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseLocalizationsScope(
            bundle: const ArchbaseLocalizationsEnUs(),
            child: Builder(
              builder: (context) {
                l = ArchbaseLocalizations.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(l, isA<ArchbaseLocalizationsEnUs>());
      expect(l.save, 'Save');
    });
  });
}
