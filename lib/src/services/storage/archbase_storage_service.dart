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
              // No macOS o keychain "data protection" (padrão do plugin) exige o
              // entitlement keychain-access-groups e falha silenciosamente em
              // builds assinados localmente (OSStatus -34018/13). O keychain
              // clássico funciona em qualquer assinatura.
              mOptions: MacOsOptions(useDataProtectionKeyChain: false),
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

  // O `ArchbaseAuthInterceptor` lê o token a cada requisição. Ir ao keystore/keychain em toda
  // leitura custa dezenas a centenas de ms por chamada no Android, e as leituras entram em fila:
  // uma tela que dispara 8 requisições espera o armazenamento seguro 8 vezes. A leitura passa a
  // ser guardada em memória por chave — e, enquanto a primeira está em andamento, as demais
  // esperam a mesma, sem disparar outras. Toda escrita e remoção por este serviço atualiza a
  // memória; quem gravar no armazenamento seguro por fora dele não é visto até o app reabrir.
  final Map<String, Future<String?>> _secureCache = {};

  Future<String?> readSecure(String key) {
    final emMemoria = _secureCache[key];
    if (emMemoria != null) return emMemoria;
    final lendo = _secure.read(key: key);
    _secureCache[key] = lendo;
    // Falha na leitura não fica guardada: a próxima tenta de novo.
    lendo.catchError((Object _) {
      if (identical(_secureCache[key], lendo)) _secureCache.remove(key);
      return null;
    });
    return lendo;
  }

  Future<void> writeSecure(String key, String value) async {
    // Tira da memória antes de gravar: se a gravação falhar, a próxima leitura vai ao
    // armazenamento em vez de devolver um valor que não chegou a ser gravado.
    _secureCache.remove(key);
    await _secure.write(key: key, value: value);
    _secureCache[key] = Future.value(value);
  }

  Future<void> removeSecure(String key) async {
    _secureCache.remove(key);
    await _secure.delete(key: key);
    _secureCache[key] = Future.value(null);
  }

  Future<void> clearSecure() async {
    _secureCache.clear();
    await _secure.deleteAll();
  }

  // --- Misc ----------------------------------------------------------------

  Future<bool> contains(String key) async => _prefs.containsKey(key);

  /// Limpa todas as preferências (não secure).
  Future<void> clearAll() async {
    await _prefs.clear();
    notifyListeners();
  }
}
