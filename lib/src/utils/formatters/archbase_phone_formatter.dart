import 'package:flutter/services.dart';

/// Formatadores e máscaras para telefone, CPF e CNPJ.
class ArchbasePhoneFormatter {
  ArchbasePhoneFormatter._();

  /// Recebe somente dígitos e devolve `(11) 91234-5678` ou `(11) 1234-5678`.
  static String formatPhoneBr(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    if (d.length == 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return raw;
  }

  static String formatCpf(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return raw;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String formatCnpj(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 14) return raw;
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }

  static String formatCep(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return raw;
    return '${d.substring(0, 5)}-${d.substring(5)}';
  }
}

/// `TextInputFormatter` que aplica uma máscara estilo `(##) #####-####`.
///
/// Caracteres `#` representam dígitos. Qualquer outro caractere é literal.
class ArchbaseMaskFormatter extends TextInputFormatter {
  ArchbaseMaskFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int idx = 0;
    for (int i = 0; i < mask.length && idx < digits.length; i++) {
      final ch = mask[i];
      if (ch == '#') {
        buffer.write(digits[idx]);
        idx++;
      } else {
        buffer.write(ch);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // Máscaras pré-definidas
  static final phoneBr = ArchbaseMaskFormatter('(##) #####-####');
  static final phoneFixoBr = ArchbaseMaskFormatter('(##) ####-####');
  static final cpf = ArchbaseMaskFormatter('###.###.###-##');
  static final cnpj = ArchbaseMaskFormatter('##.###.###/####-##');
  static final cep = ArchbaseMaskFormatter('#####-###');
  static final dateBr = ArchbaseMaskFormatter('##/##/####');
  static final cnh = ArchbaseMaskFormatter('###########');
  static final creditCard = ArchbaseMaskFormatter('#### #### #### ####');
}

/// Formatter para placa de veículo brasileira aceitando padrão antigo
/// (AAA-9999) e Mercosul (AAA9A99). Aceita letras e dígitos, força
/// uppercase, limita a 7 caracteres alfanuméricos.
class ArchbasePlateFormatter extends TextInputFormatter {
  static final _allowed = RegExp(r'[A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase();
    final filtered =
        raw.split('').where((c) => _allowed.hasMatch(c)).take(7).join();
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
