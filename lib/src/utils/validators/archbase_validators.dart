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
