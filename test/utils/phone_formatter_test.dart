import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchbasePhoneFormatter', () {
    test('formatPhoneBr 11 dígitos', () {
      expect(
        ArchbasePhoneFormatter.formatPhoneBr('11912345678'),
        '(11) 91234-5678',
      );
    });
    test('formatPhoneBr 10 dígitos', () {
      expect(
        ArchbasePhoneFormatter.formatPhoneBr('1132345678'),
        '(11) 3234-5678',
      );
    });
    test('formatCpf', () {
      expect(
        ArchbasePhoneFormatter.formatCpf('52998224725'),
        '529.982.247-25',
      );
    });
    test('formatCnpj', () {
      expect(
        ArchbasePhoneFormatter.formatCnpj('11444777000161'),
        '11.444.777/0001-61',
      );
    });
    test('formatCep', () {
      expect(ArchbasePhoneFormatter.formatCep('01310100'), '01310-100');
    });
  });

  group('ArchbaseMaskFormatter', () {
    test('aplica máscara progressivamente conforme digita', () {
      final mask = ArchbaseMaskFormatter.cpf;
      var v = mask.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '5'),
      );
      expect(v.text, '5');
      v = mask.formatEditUpdate(v, const TextEditingValue(text: '52998'));
      expect(v.text, '529.98');
      v = mask.formatEditUpdate(v,
          const TextEditingValue(text: '52998224725'));
      expect(v.text, '529.982.247-25');
    });

    test('phoneBr 11 dígitos resulta em (##) #####-####', () {
      final v = ArchbaseMaskFormatter.phoneBr.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11912345678'),
      );
      expect(v.text, '(11) 91234-5678');
    });

    test('cep aplica # ##### - ###', () {
      final v = ArchbaseMaskFormatter.cep.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '01310100'),
      );
      expect(v.text, '01310-100');
    });
  });
}
