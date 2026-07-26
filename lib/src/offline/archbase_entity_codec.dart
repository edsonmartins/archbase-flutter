/// Registro de tipos de domínio ↔ JSON, para o store genérico.
///
/// O store guarda entidades como JSON numa tabela única; o app registra um codec
/// por tipo sincronizável (toJson/fromJson). Sem codegen; sem tabela por tipo.
library;

import 'archbase_syncable.dart';

/// Serializa/desserializa um modelo de domínio [T].
class ArchbaseEntityCodec<T extends ArchbaseSyncable> {
  const ArchbaseEntityCodec({
    required this.typeName,
    required this.fromJson,
    required this.toJson,
  });

  /// Nome estável do tipo, gravado na coluna `type` (ex.: 'Visita').
  final String typeName;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T model) toJson;

  /// Serializa aceitando a interface (o cast para [T] é interno). Necessário
  /// porque `Map Function(T)` não é subtipo de `Map Function(ArchbaseSyncable)`
  /// (contravariância) — o store chama por aqui quando só tem a interface.
  Map<String, dynamic> encode(ArchbaseSyncable model) => toJson(model as T);
}

/// Mapa de codecs por [Type] e por nome. Preenchido pelo app no bootstrap.
class ArchbaseEntityRegistry {
  final _byType = <Type, ArchbaseEntityCodec>{};
  final _byName = <String, ArchbaseEntityCodec>{};

  void register<T extends ArchbaseSyncable>(ArchbaseEntityCodec<T> codec) {
    _byType[T] = codec;
    _byName[codec.typeName] = codec;
  }

  /// Codec pelo tipo estático [T] (leituras/consultas).
  ArchbaseEntityCodec<T> codecOf<T extends ArchbaseSyncable>() {
    final c = _byType[T];
    if (c == null) {
      throw StateError('Nenhum ArchbaseEntityCodec registrado para $T');
    }
    return c as ArchbaseEntityCodec<T>;
  }

  /// Codec pelo tipo em runtime (usado no upsert, onde T pode ser a interface).
  ArchbaseEntityCodec codecForRuntime(ArchbaseSyncable model) {
    final c = _byType[model.runtimeType];
    if (c == null) {
      throw StateError(
          'Nenhum ArchbaseEntityCodec registrado para ${model.runtimeType}');
    }
    return c;
  }

  ArchbaseEntityCodec? codecByName(String typeName) => _byName[typeName];
  String typeNameOf<T extends ArchbaseSyncable>() => codecOf<T>().typeName;
}
