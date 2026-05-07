import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchbaseValidators.required', () {
    test('null/vazio/whitespace devolve mensagem', () {
      expect(ArchbaseValidators.required(null), isNotNull);
      expect(ArchbaseValidators.required(''), isNotNull);
      expect(ArchbaseValidators.required('   '), isNotNull);
    });
    test('texto não-vazio passa', () {
      expect(ArchbaseValidators.required('x'), isNull);
    });
  });

  group('ArchbaseValidators.email', () {
    test('aceita formatos comuns', () {
      expect(ArchbaseValidators.email('a@b.co'), isNull);
      expect(ArchbaseValidators.email('edson.martins@archbase.dev'), isNull);
    });
    test('rejeita formatos inválidos', () {
      expect(ArchbaseValidators.email('a@b'), isNotNull);
      expect(ArchbaseValidators.email('a.b.c'), isNotNull);
      expect(ArchbaseValidators.email(''), isNotNull);
    });
    test('allowEmpty=true permite vazio', () {
      expect(ArchbaseValidators.email('', allowEmpty: true), isNull);
    });
  });

  group('ArchbaseValidators.cpf / cnpj', () {
    // CPFs e CNPJs gerados a partir de algoritmo de validação.
    test('CPF válido (529.982.247-25) passa', () {
      expect(ArchbaseValidators.cpf('529.982.247-25'), isNull);
    });
    test('CPF "111.111.111-11" reprovado', () {
      expect(ArchbaseValidators.cpf('111.111.111-11'), isNotNull);
    });
    test('CNPJ válido (11.444.777/0001-61) passa', () {
      expect(ArchbaseValidators.cnpj('11.444.777/0001-61'), isNull);
    });
    test('CNPJ inválido reprovado', () {
      expect(ArchbaseValidators.cnpj('00.000.000/0000-00'), isNotNull);
    });

    test('cpfOrCnpj escolhe pelo tamanho', () {
      expect(ArchbaseValidators.cpfOrCnpj('529.982.247-25'), isNull);
      expect(ArchbaseValidators.cpfOrCnpj('11.444.777/0001-61'), isNull);
      expect(ArchbaseValidators.cpfOrCnpj('123'), isNotNull);
    });
  });

  group('ArchbaseValidators.phoneBr', () {
    test('aceita celular (11 dígitos) e fixo (10 dígitos)', () {
      expect(ArchbaseValidators.phoneBr('(11) 91234-5678'), isNull);
      expect(ArchbaseValidators.phoneBr('(11) 1234-5678'), isNull);
    });
    test('rejeita comprimentos diferentes', () {
      expect(ArchbaseValidators.phoneBr('1234'), isNotNull);
      expect(ArchbaseValidators.phoneBr('123456789012'), isNotNull);
    });
  });

  group('ArchbaseValidators.strongPassword', () {
    test('aceita senha 8+ com maiúscula, minúscula, número e símbolo', () {
      expect(ArchbaseValidators.strongPassword('Archbase!1'), isNull);
      expect(ArchbaseValidators.strongPassword('Senh@2026'), isNull);
    });
    test('rejeita senhas fracas', () {
      expect(ArchbaseValidators.strongPassword('senha'), isNotNull);
      expect(ArchbaseValidators.strongPassword('SenhaSemNum!'), isNotNull);
      expect(ArchbaseValidators.strongPassword('Senha1234'),
          isNotNull); // sem símbolo
    });
  });

  group('ArchbaseValidators.confirm', () {
    test('valores iguais passam', () {
      expect(ArchbaseValidators.confirm('abc', 'abc'), isNull);
    });
    test('valores diferentes reprovam', () {
      expect(ArchbaseValidators.confirm('abc', 'xyz'), isNotNull);
    });
  });

  group('ArchbaseValidators.compose', () {
    test('roda em sequência e devolve primeiro erro', () {
      final v = ArchbaseValidators.compose([
        ArchbaseValidators.required,
        ArchbaseValidators.email,
      ]);
      expect(v(null), isNotNull); // bate em required
      expect(v('a@b'), isNotNull); // passa em required, falha em email
      expect(v('a@b.co'), isNull);
    });
  });

  group('ArchbaseValidators.minLength / maxLength', () {
    test('minLength reprova abaixo', () {
      expect(ArchbaseValidators.minLength('ab', 3), isNotNull);
      expect(ArchbaseValidators.minLength('abc', 3), isNull);
    });
    test('maxLength reprova acima', () {
      expect(ArchbaseValidators.maxLength('abcd', 3), isNotNull);
      expect(ArchbaseValidators.maxLength('abc', 3), isNull);
      expect(ArchbaseValidators.maxLength(null, 3), isNull);
    });
  });
}
