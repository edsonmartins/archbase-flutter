import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';

/// Conjunto de validadores brasileiros prontos para uso em `TextFormField`.
///
/// Todos retornam `null` quando o valor é válido, ou a mensagem de erro
/// (em pt-BR) quando inválido — formato esperado por `validator:`.
class ArchbaseValidators {
  ArchbaseValidators._();

  static final RegExp _emailRe = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _strongPwd = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~_\-+%^.,;:?<>\(\)\[\]\{\}|/\\]).{8,}$',
  );

  static String? required(
    String? value, {
    String message = 'Campo obrigatório',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? minLength(String? value, int min, {String? message}) {
    if (value == null || value.length < min) {
      return message ?? 'Mínimo de $min caracteres';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String? message}) {
    if (value != null && value.length > max) {
      return message ?? 'Máximo de $max caracteres';
    }
    return null;
  }

  static String? email(
    String? value, {
    String message = 'E-mail inválido',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    if (!_emailRe.hasMatch(value.trim())) return message;
    return null;
  }

  static String? cpf(
    String? value, {
    String message = 'CPF inválido',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    return CPFValidator.isValid(value) ? null : message;
  }

  static String? cnpj(
    String? value, {
    String message = 'CNPJ inválido',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    return CNPJValidator.isValid(value) ? null : message;
  }

  static String? cpfOrCnpj(String? value, {bool allowEmpty = false}) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'CPF/CNPJ obrigatório';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) return cpf(value);
    if (digits.length == 14) return cnpj(value);
    return 'CPF/CNPJ inválido';
  }

  static String? phoneBr(
    String? value, {
    String message = 'Telefone inválido',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) return message;
    return null;
  }

  /// Valida CNH (Carteira Nacional de Habilitação) brasileira — 11 dígitos
  /// com algoritmo de verificação dos 2 últimos.
  static String? cnh(
    String? value, {
    String message = 'CNH inválida',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return message;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return message;

    int dsc = 0;
    int v = 0;
    for (int i = 0, j = 9; i < 9; i++, j--) {
      v += int.parse(digits[i]) * j;
    }
    int dv1 = v % 11;
    if (dv1 >= 10) {
      dv1 = 0;
      dsc = 2;
    }
    v = 0;
    for (int i = 0, j = 1; i < 9; i++, j++) {
      v += int.parse(digits[i]) * j;
    }
    int dv2 = (v % 11) - dsc;
    if (dv2 < 0) dv2 += 11;
    if (dv2 >= 10) dv2 = 0;
    if (dv1 != int.parse(digits[9]) || dv2 != int.parse(digits[10])) {
      return message;
    }
    return null;
  }

  /// Valida placa de veículo brasileira: padrão antigo `AAA-9999` ou
  /// Mercosul `AAA9A99`.
  static String? plateBr(
    String? value, {
    String message = 'Placa inválida',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final mercosul = RegExp(r'^[A-Z]{3}\d[A-Z]\d{2}$');
    final antiga = RegExp(r'^[A-Z]{3}\d{4}$');
    if (mercosul.hasMatch(cleaned) || antiga.hasMatch(cleaned)) return null;
    return message;
  }

  /// Valida idade mínima a partir de uma data de nascimento (DateTime
  /// ou ISO string).
  static String? Function(String?) ageMin(
    int minYears, {
    String message = 'Idade mínima não atingida',
  }) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      DateTime? birth;
      if (value.contains('/')) {
        // dd/MM/yyyy
        final parts = value.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            birth = DateTime(y, m, d);
          }
        }
      }
      birth ??= DateTime.tryParse(value);
      if (birth == null) return 'Data inválida';
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      if (age < minYears) return message;
      return null;
    };
  }

  /// URL HTTP/HTTPS válida.
  static String? url(
    String? value, {
    String message = 'URL inválida',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.isAbsolute) return message;
    if (!{'http', 'https'}.contains(uri.scheme)) return message;
    return null;
  }

  /// Igualdade entre dois valores — útil para "campo X igual a Y".
  static String? Function(String?) equal(
    Object? other, {
    String message = 'Valores não coincidem',
  }) {
    return (value) => value == other?.toString() ? null : message;
  }

  /// Diferença entre dois valores.
  static String? Function(String?) notEqual(
    Object? other, {
    String message = 'Valor não pode ser igual',
  }) {
    return (value) => value != other?.toString() ? null : message;
  }

  /// Casamento por padrão regex.
  static String? Function(String?) pattern(
    Pattern pattern, {
    String message = 'Formato inválido',
  }) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final re = pattern is RegExp ? pattern : RegExp(pattern.toString());
      return re.hasMatch(value) ? null : message;
    };
  }

  /// Número entre [min] e [max] (inclusivos).
  static String? Function(String?) numericBetween(
    num min,
    num max, {
    String? message,
  }) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final n = num.tryParse(value.replaceAll(',', '.'));
      if (n == null) return message ?? 'Número inválido';
      if (n < min || n > max) {
        return message ?? 'Valor deve estar entre $min e $max';
      }
      return null;
    };
  }

  /// Cartão de crédito (Luhn check).
  static String? creditCard(
    String? value, {
    String message = 'Número de cartão inválido',
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) return allowEmpty ? null : message;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return message;
    int sum = 0;
    bool alt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0 ? null : message;
  }

  /// Senha forte (default Archbase): 8+ caracteres, maiúscula, minúscula,
  /// número e um caractere especial.
  static String? strongPassword(
    String? value, {
    int minLength = 8,
    String message =
        'Senha precisa ter 8+ caracteres, com maiúscula, minúscula, número e símbolo',
  }) {
    if (value == null || value.length < minLength) return message;
    return _strongPwd.hasMatch(value) ? null : message;
  }

  static String? confirm(
    String? value,
    String? other, {
    String message = 'Os valores não coincidem',
  }) {
    if (value != other) return message;
    return null;
  }

  /// Compose: roda múltiplos validadores em sequência, devolvendo o primeiro erro.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
