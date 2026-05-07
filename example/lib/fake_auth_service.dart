import 'dart:async';

import 'package:archbase_flutter/archbase_flutter.dart';

/// Implementação fake de [ArchbaseAuthService] usando [SimpleArchbaseUser].
///
/// Substitua `performLogin` e `performRefresh` pelas chamadas reais à
/// sua API. O resto (persistência de token, refresh coordenado, header
/// `Bearer` no Dio) já está pronto.
class FakeAuthService extends ArchbaseAuthService<SimpleArchbaseUser> {
  FakeAuthService({
    required super.apiClient,
    required super.tokens,
  }) : super(userFromJson: SimpleArchbaseUser.fromJson);

  @override
  Future<ArchbaseLoginResult<SimpleArchbaseUser>> performLogin(
    Map<String, dynamic> credentials,
  ) async {
    // Simula latência de rede.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final username = credentials['username']?.toString() ?? '';
    final password = credentials['password']?.toString() ?? '';
    if (password.length < 4) {
      throw InvalidCredentialsException();
    }
    return ArchbaseLoginResult<SimpleArchbaseUser>(
      tokens: ArchbaseTokenSet(
        accessToken: 'fake-access-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'fake-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      ),
      user: SimpleArchbaseUser(
        id: 'u-1',
        displayName: username.split('@').first,
        email: username,
        roles: const ['USER'],
      ),
    );
  }

  @override
  Future<ArchbaseTokenSet> performRefresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ArchbaseTokenSet(
      accessToken: 'fake-access-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }
}
