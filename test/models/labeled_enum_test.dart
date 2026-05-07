import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Status with LabeledEnum {
  ativo('ATIVO', 'Ativo'),
  inativo('INATIVO', 'Inativo');

  const _Status(this.value, this.label);

  @override
  final String value;
  @override
  final String label;
}

void main() {
  group('LabeledEnums.fromString', () {
    test('encontra valor case-insensitive', () {
      expect(LabeledEnums.fromString(_Status.values, 'ativo'), _Status.ativo);
      expect(LabeledEnums.fromString(_Status.values, 'ATIVO'), _Status.ativo);
    });

    test('respeita aliases', () {
      final result = LabeledEnums.fromString(
        _Status.values,
        'DESLIGADO',
        aliases: {'DESLIGADO': _Status.inativo},
      );
      expect(result, _Status.inativo);
    });

    test('usa defaultValue quando nada bate', () {
      final result = LabeledEnums.fromString(
        _Status.values,
        'XPTO',
        defaultValue: _Status.inativo,
      );
      expect(result, _Status.inativo);
    });

    test('cai no primeiro valor quando não tem default', () {
      expect(LabeledEnums.fromString(_Status.values, null), _Status.ativo);
      expect(LabeledEnums.fromString(_Status.values, 'desconhecido'),
          _Status.ativo);
    });
  });
}
