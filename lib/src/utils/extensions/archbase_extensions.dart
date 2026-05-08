import 'package:flutter/material.dart';

/// Conjunto curado de extensions para uso geral. Selecionadas por
/// utilidade real e ergonomia — evitamos extensões que apenas envolvem
/// API já curta da stdlib.

extension ArchbaseStringX on String {
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;

  /// Capitaliza apenas a primeira letra. `'edson' → 'Edson'`.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitaliza cada palavra. `'edson martins' → 'Edson Martins'`.
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((w) => w.capitalize()).join(' ');
  }

  /// Trunca para [max] e adiciona [ellipsis] se cortou.
  String truncate(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    return '${substring(0, max)}$ellipsis';
  }

  /// Devolve apenas dígitos.
  String onlyDigits() => replaceAll(RegExp(r'\D'), '');

  /// Devolve sem caracteres especiais (mantém alfanuméricos + espaço).
  String onlyAlphanumeric() => replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '');

  /// Converte para int, devolvendo `null` em falha.
  int? toIntOrNull() => int.tryParse(this);

  /// Converte para double, devolvendo `null` em falha. Aceita vírgula BR.
  double? toDoubleBrOrNull() => double.tryParse(replaceAll(',', '.'));

  /// As 1-2 iniciais do texto (útil para avatares).
  String initials({int max = 2}) {
    final parts =
        trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    final taken = parts.take(max).map((p) => p[0].toUpperCase()).join();
    return taken;
  }

  /// Ofusca um texto sensível mostrando só os últimos [visible] chars.
  String mask({int visible = 4, String char = '•'}) {
    if (length <= visible) return this;
    final hidden = char * (length - visible);
    return '$hidden${substring(length - visible)}';
  }
}

extension ArchbaseNumX on num {
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;

  /// Limita o valor entre [min] e [max].
  num clampTo(num min, num max) => this < min ? min : (this > max ? max : this);
}

extension ArchbaseDateTimeX on DateTime {
  /// `true` se [other] está no mesmo ano/mês/dia.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDay(DateTime.now());

  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// 00:00:00 do mesmo dia.
  DateTime get startOfDay => DateTime(year, month, day);

  /// 23:59:59.999 do mesmo dia.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Quantidade de dias inteiros entre `this` e [other] (positivo se
  /// [other] está no futuro).
  int daysUntil(DateTime other) =>
      other.startOfDay.difference(startOfDay).inDays;
}

extension ArchbaseListX<T> on List<T> {
  /// Devolve null em vez de lançar quando o índice é inválido.
  T? tryGet(int index) => (index >= 0 && index < length) ? this[index] : null;

  /// Quebra a lista em pedaços de [size] elementos.
  List<List<T>> chunked(int size) {
    if (size <= 0) return [List.of(this)];
    return [
      for (var i = 0; i < length; i += size)
        sublist(i, (i + size).clamp(0, length)),
    ];
  }

  /// Insere [separator] entre elementos consecutivos.
  List<T> separatedBy(T separator) {
    if (length <= 1) return List.of(this);
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }
}

extension ArchbaseIterableX<T> on Iterable<T> {
  /// firstWhere com null em vez de exception.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

extension ArchbaseMapX<K, V> on Map<K, V> {
  /// Ignora null values.
  Map<K, V> compact() {
    return {
      for (final e in entries)
        if (e.value != null) e.key: e.value,
    };
  }
}

extension ArchbaseBuildContextX on BuildContext {
  /// Atalhos para MediaQuery.
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Atalhos de Theme.
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  /// Esconde teclado em foco.
  void unfocus() => FocusScope.of(this).unfocus();

  /// Fecha telas/dialogs em sequência até a condição parar.
  void popUntil(bool Function(Route<dynamic>) predicate) =>
      Navigator.of(this).popUntil(predicate);

  /// Mostra um SnackBar simples.
  void showSnack(String message, {Color? color, Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
