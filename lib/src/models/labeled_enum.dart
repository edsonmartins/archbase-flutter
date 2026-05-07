/// Mixin para enums com `value` (string usada na API) e `label` (texto exibível).
///
/// Uso típico:
/// ```dart
/// enum Status with LabeledEnum {
///   ativo('ATIVO', 'Ativo'),
///   inativo('INATIVO', 'Inativo');
///
///   const Status(this.value, this.label);
///
///   @override final String value;
///   @override final String label;
/// }
///
/// final s = LabeledEnums.fromString(Status.values, 'ATIVO');
/// ```
mixin LabeledEnum {
  String get value;
  String get label;
}

class LabeledEnums {
  LabeledEnums._();

  /// Localiza o enum cujo `value` (case-insensitive) bate com [raw].
  /// Retorna [defaultValue] se nada bater (ou o primeiro valor da lista).
  static T fromString<T extends LabeledEnum>(
    List<T> values,
    String? raw, {
    T? defaultValue,
    Map<String, T>? aliases,
  }) {
    if (raw == null) return defaultValue ?? values.first;
    final normalized = raw.trim().toUpperCase();
    if (aliases != null) {
      for (final entry in aliases.entries) {
        if (entry.key.toUpperCase() == normalized) return entry.value;
      }
    }
    for (final v in values) {
      if (v.value.toUpperCase() == normalized) return v;
    }
    return defaultValue ?? values.first;
  }
}
