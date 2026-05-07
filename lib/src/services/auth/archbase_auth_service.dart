import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/exceptions/auth_exception.dart';
import '../../core/state/archbase_service.dart';
import '../api/archbase_api_client.dart';
import 'archbase_token_holder.dart';
import 'archbase_user.dart';

/// Resultado bem-sucedido de uma autenticação.
class ArchbaseLoginResult<U extends ArchbaseUser> {
  ArchbaseLoginResult({required this.tokens, required this.user});

  final ArchbaseTokenSet tokens;
  final U user;
}

/// Serviço de autenticação genérico.
///
/// Concretize informando como fazer login (`performLogin`) e como renovar o
/// token (`performRefresh`) — o resto (persistência, refresh coordenado,
/// header Bearer no Dio) já está pronto.
abstract class ArchbaseAuthService<U extends ArchbaseUser>
    extends ArchbaseService {
  ArchbaseAuthService({
    required this.apiClient,
    required this.tokens,
    required this.userFromJson,
  });

  final ArchbaseApiClient apiClient;
  final ArchbaseTokenHolder tokens;
  final U Function(Map<String, dynamic> json) userFromJson;

  final ValueNotifier<U?> currentUser = ValueNotifier<U?>(null);
  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  final _onLoggedInController = StreamController<U>.broadcast();
  final _onLoggedOutController = StreamController<void>.broadcast();

  Stream<U> get onLoggedIn => _onLoggedInController.stream;
  Stream<void> get onLoggedOut => _onLoggedOutController.stream;

  // ---- API que o app precisa implementar ---------------------------------

  /// Executa a chamada concreta de login (a partir das credenciais).
  /// Deve devolver tokens + user.
  Future<ArchbaseLoginResult<U>> performLogin(
    Map<String, dynamic> credentials,
  );

  /// Executa o refresh chamando o endpoint configurado.
  /// Recebe o `refreshToken` salvo. Devolve o novo `ArchbaseTokenSet`.
  Future<ArchbaseTokenSet> performRefresh(String refreshToken);

  /// (opcional) Chama o endpoint de logout no backend. Default: noop.
  Future<void> performRemoteLogout() async {}

  // ---- Lifecycle ---------------------------------------------------------

  @override
  Future<void> onInit() async {
    apiClient.setRefreshCallback(
      refresh: _refreshFlow,
      onAuthFailure: () async => logout(),
    );
    await _restoreFromStorage();
  }

  Future<void> _restoreFromStorage() async {
    final token = await tokens.readAccessToken();
    final json = await tokens.readUserJson();
    if (token != null && json != null) {
      currentUser.value = userFromJson(json);
      isAuthenticated.value = true;
      notifyListeners();
    }
  }

  // ---- Login / Logout ----------------------------------------------------

  Future<U> login(Map<String, dynamic> credentials) async {
    final result = await performLogin(credentials);
    await tokens.save(result.tokens);
    await tokens.saveUserJson(result.user.toJson());
    currentUser.value = result.user;
    isAuthenticated.value = true;
    _onLoggedInController.add(result.user);
    notifyListeners();
    return result.user;
  }

  Future<void> logout({bool callRemote = true}) async {
    if (callRemote) {
      try {
        await performRemoteLogout();
      } catch (_) {
        // Ignora falha — o logout local é o que importa.
      }
    }
    await tokens.clear();
    await tokens.clearUser();
    currentUser.value = null;
    isAuthenticated.value = false;
    _onLoggedOutController.add(null);
    notifyListeners();
  }

  // ---- Refresh -----------------------------------------------------------

  Future<String> _refreshFlow() async {
    final refresh = await tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw RefreshFailedException('Sem refresh token armazenado');
    }
    final newTokens = await performRefresh(refresh);
    await tokens.save(newTokens);
    return newTokens.accessToken;
  }

  // ---- Helpers para o app ------------------------------------------------

  U requireUser() {
    final user = currentUser.value;
    if (user == null) {
      throw AuthException('Usuário não autenticado');
    }
    return user;
  }

  bool get hasValidSession => isAuthenticated.value;

  @override
  Future<void> onDispose() async {
    await _onLoggedInController.close();
    await _onLoggedOutController.close();
    currentUser.dispose();
    isAuthenticated.dispose();
  }
}
