import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state/archbase_service.dart';

/// Wrapper unificado sobre [SharedPreferences] e [FlutterSecureStorage].
///
/// - Use [read]/[write] para dados simples.
/// - Use [readSecure]/[writeSecure] para tokens e credenciais.
/// - Helpers tipados para `bool`, `int`, `double`, `DateTime` e `Map`.
class ArchbaseStorageService extends ArchbaseService {
  ArchbaseStorageService({FlutterSecureStorage? secure})
      : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _secure;
  late SharedPreferences _prefs;

  @override
  Future<void> onInit() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Plain ---------------------------------------------------------------

  Future<String?> read(String key) async => _prefs.getString(key);

  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
    notifyListeners();
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
    notifyListeners();
  }

  Future<bool?> readBool(String key) async => _prefs.getBool(key);

  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
  }

  Future<int?> readInt(String key) async => _prefs.getInt(key);

  Future<void> writeInt(String key, int value) async {
    await _prefs.setInt(key, value);
    notifyListeners();
  }

  Future<double?> readDouble(String key) async => _prefs.getDouble(key);

  Future<void> writeDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
    notifyListeners();
  }

  Future<DateTime?> readDate(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeDate(String key, DateTime value) async {
    await _prefs.setString(key, value.toIso8601String());
    notifyListeners();
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
    notifyListeners();
  }

  // --- Secure --------------------------------------------------------------

  Future<String?> readSecure(String key) => _secure.read(key: key);

  Future<void> writeSecure(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<void> removeSecure(String key) => _secure.delete(key: key);

  Future<void> clearSecure() => _secure.deleteAll();

  // --- Misc ----------------------------------------------------------------

  Future<bool> contains(String key) async => _prefs.containsKey(key);

  /// Limpa todas as preferências (não secure).
  Future<void> clearAll() async {
    await _prefs.clear();
    notifyListeners();
  }
}
