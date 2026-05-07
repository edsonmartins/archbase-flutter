import 'dart:convert';

import '../../core/archbase_storage_keys.dart';
import '../storage/archbase_storage_service.dart';

/// Pacote de tokens devolvido pelo backend após login/refresh.
class ArchbaseTokenSet {
  ArchbaseTokenSet({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory ArchbaseTokenSet.fromJson(Map<String, dynamic> json) {
    DateTime? expires;
    if (json['expiresAt'] != null) {
      expires = DateTime.tryParse(json['expiresAt'].toString());
    } else if (json['expiresIn'] is num) {
      expires = DateTime.now()
          .add(Duration(seconds: (json['expiresIn'] as num).toInt()));
    }
    return ArchbaseTokenSet(
      accessToken: (json['accessToken'] ?? json['access_token'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? json['refresh_token'])?.toString(),
      expiresAt: expires,
    );
  }
}

/// Persiste tokens em [ArchbaseStorageService] (secure) e expõe acesso síncrono.
class ArchbaseTokenHolder {
  ArchbaseTokenHolder(this._storage);

  final ArchbaseStorageService _storage;

  Future<void> save(ArchbaseTokenSet tokens) async {
    await _storage.writeSecure(
      ArchbaseStorageKeys.accessToken,
      tokens.accessToken,
    );
    if (tokens.refreshToken != null) {
      await _storage.writeSecure(
        ArchbaseStorageKeys.refreshToken,
        tokens.refreshToken!,
      );
    }
    if (tokens.expiresAt != null) {
      await _storage.write(
        ArchbaseStorageKeys.tokenExpiresAt,
        tokens.expiresAt!.toIso8601String(),
      );
    }
  }

  Future<String?> readAccessToken() =>
      _storage.readSecure(ArchbaseStorageKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.readSecure(ArchbaseStorageKeys.refreshToken);

  Future<DateTime?> readExpiresAt() =>
      _storage.readDate(ArchbaseStorageKeys.tokenExpiresAt);

  Future<void> clear() async {
    await _storage.removeSecure(ArchbaseStorageKeys.accessToken);
    await _storage.removeSecure(ArchbaseStorageKeys.refreshToken);
    await _storage.remove(ArchbaseStorageKeys.tokenExpiresAt);
  }

  /// Persiste um JSON arbitrário do usuário (para reabertura sem rede).
  Future<void> saveUserJson(Map<String, dynamic> user) async {
    await _storage.write(
      ArchbaseStorageKeys.currentUser,
      jsonEncode(user),
    );
  }

  Future<Map<String, dynamic>?> readUserJson() =>
      _storage.readJson(ArchbaseStorageKeys.currentUser);

  Future<void> clearUser() => _storage.remove(ArchbaseStorageKeys.currentUser);
}
