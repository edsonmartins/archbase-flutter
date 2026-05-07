import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResponse', () {
    test('success carrega data, isSuccess=true e orThrow devolve o valor', () {
      final r = ApiResponse<int>.success(42, statusCode: 200);
      expect(r.isSuccess, isTrue);
      expect(r.isError, isFalse);
      expect(r.data, 42);
      expect(r.statusCode, 200);
      expect(r.orThrow(), 42);
    });

    test('error preserva mensagem, status e fieldErrors', () {
      final r = ApiResponse<int>.error(
        'Falhou',
        statusCode: 400,
        fieldErrors: [
          ApiFieldError(field: 'cpf', message: 'inválido'),
        ],
      );
      expect(r.isError, isTrue);
      expect(r.message, 'Falhou');
      expect(r.statusCode, 400);
      expect(r.hasFieldErrors, isTrue);
      expect(r.fieldErrors.first.field, 'cpf');
    });

    test('orThrow lança ApiException em erro', () {
      final r = ApiResponse<int>.error('Boom', statusCode: 500);
      expect(
        () => r.orThrow(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('map em sucesso transforma o tipo', () {
      final r = ApiResponse<int>.success(2);
      final mapped = r.map<String>((v) => 'v=$v');
      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, 'v=2');
    });

    test('map em erro propaga sem chamar mapper', () {
      var called = false;
      final r = ApiResponse<int>.error('x');
      final mapped = r.map<String>((v) {
        called = true;
        return 'never';
      });
      expect(called, isFalse);
      expect(mapped.isError, isTrue);
      expect(mapped.message, 'x');
    });
  });
}
