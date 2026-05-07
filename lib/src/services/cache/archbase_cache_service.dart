import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/archbase_storage_keys.dart';
import '../../core/state/archbase_service.dart';

class _CacheEntry {
  _CacheEntry({required this.payload, required this.expiresAt});

  final String payload;
  final DateTime expiresAt;

  Map<String, dynamic> toMap() => {
        'payload': payload,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory _CacheEntry.fromMap(Map map) {
    return _CacheEntry(
      payload: map['payload'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache em disco baseado em [Hive] com TTL.
///
/// - `set` aceita objetos serializáveis (`toJson` / `Map` / `List` / primitivos).
/// - `get<T>` precisa de um `fromJson` para reconstruir objetos.
class ArchbaseCacheService extends ArchbaseService {
  ArchbaseCacheService({Duration? defaultTtl, String? boxName})
      : _defaultTtl = defaultTtl ?? const Duration(minutes: 30),
        _boxName = boxName ?? ArchbaseStorageKeys.cacheBox;

  final Duration _defaultTtl;
  final String _boxName;

  late LazyBox<Map> _box;

  @override
  Future<void> onInit() async {
    _box = await Hive.openLazyBox<Map>(_boxName);
    // Limpeza assíncrona de expirados no startup, sem bloquear init.
    unawaited(_purgeExpired());
  }

  Future<void> set(
    String key,
    dynamic value, {
    Duration? ttl,
  }) async {
    final entry = _CacheEntry(
      payload: jsonEncode(_normalize(value)),
      expiresAt: DateTime.now().add(ttl ?? _defaultTtl),
    );
    await _box.put(key, entry.toMap());
  }

  Future<T?> get<T>(
    String key,
    T Function(dynamic raw) fromJson,
  ) async {
    final raw = await _box.get(key);
    if (raw == null) return null;
    final entry = _CacheEntry.fromMap(raw);
    if (entry.isExpired) {
      await _box.delete(key);
      return null;
    }
    final decoded = jsonDecode(entry.payload);
    return fromJson(decoded);
  }

  /// Variante para listas, evitando que o caller precise fazer cast.
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    return get<List<T>>(key, (raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<bool> has(String key) async {
    final raw = await _box.get(key);
    if (raw == null) return false;
    final entry = _CacheEntry.fromMap(raw);
    if (entry.isExpired) {
      await _box.delete(key);
      return false;
    }
    return true;
  }

  Future<void> remove(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();

  /// Remove entradas expiradas (chamado no startup).
  Future<void> _purgeExpired() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      final raw = await _box.get(key);
      if (raw == null) continue;
      try {
        final entry = _CacheEntry.fromMap(raw);
        if (entry.isExpired) await _box.delete(key);
      } catch (_) {
        await _box.delete(key);
      }
    }
  }

  dynamic _normalize(dynamic value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _normalize(v)));
    }
    if (value is Iterable) {
      return value.map(_normalize).toList();
    }
    // Tenta `toJson()` (DTOs Archbase).
    try {
      final dynamic dyn = value;
      final json = dyn.toJson();
      return _normalize(json);
    } catch (_) {
      return value.toString();
    }
  }
}
