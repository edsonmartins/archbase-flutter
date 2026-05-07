/// Contract mínimo para todo DTO da archbase. Permite usar `toJson` em
/// helpers genéricos. A serialização de entrada continua via factory
/// `fromJson` na classe concreta.
abstract class BaseDto {
  const BaseDto();

  Map<String, dynamic> toJson();
}

/// Helpers para parsing tolerante de JSON (compatível com múltiplos
/// formatos de backend que aparecem nos apps reais).
class JsonParse {
  JsonParse._();

  static String? string(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? integer(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? decimal(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static bool? boolean(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'true' || v == 'sim' || v == 's' || v == '1') return true;
      if (v == 'false' || v == 'nao' || v == 'não' || v == 'n' || v == '0') {
        return false;
      }
    }
    return null;
  }

  /// Parser tolerante para datas: ISO 8601, timestamps em ms ou string vazia.
  static DateTime? date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<T> list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  /// Resolve valor por uma lista de chaves alternativas
  /// (útil quando o backend renomeia campos entre versões).
  static dynamic pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) return json[key];
    }
    return null;
  }
}
