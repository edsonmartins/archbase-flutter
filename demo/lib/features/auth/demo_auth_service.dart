import 'package:archbase_flutter/archbase_flutter.dart';

/// AuthService concreto do demo. Bate em /auth/login e /auth/refresh
/// (ambos servidos pelo `MockApiAdapter`).
class DemoAuthService extends ArchbaseAuthService<SimpleArchbaseUser> {
  DemoAuthService({
    required super.apiClient,
    required super.tokens,
  }) : super(userFromJson: SimpleArchbaseUser.fromJson);

  @override
  Future<ArchbaseLoginResult<SimpleArchbaseUser>> performLogin(
    Map<String, dynamic> credentials,
  ) async {
    final response = await apiClient.postJson<Map<String, dynamic>>(
      '/auth/login',
      credentials,
      (json) => json,
    );
    if (response.isError || response.data == null) {
      throw InvalidCredentialsException(
        response.message ?? 'Falha no login',
      );
    }
    final data = response.data!;
    final tokens = ArchbaseTokenSet.fromJson(data);
    final user = SimpleArchbaseUser.fromJson(
      (data['user'] as Map).cast<String, dynamic>(),
    );
    return ArchbaseLoginResult(tokens: tokens, user: user);
  }

  @override
  Future<ArchbaseTokenSet> performRefresh(String refreshToken) async {
    final response = await apiClient.postJson<Map<String, dynamic>>(
      '/auth/refresh',
      {'refreshToken': refreshToken},
      (json) => json,
    );
    if (response.isError || response.data == null) {
      throw RefreshFailedException(response.message ?? 'Refresh falhou');
    }
    return ArchbaseTokenSet.fromJson(response.data!);
  }

  @override
  Future<void> performRemoteLogout() async {
    try {
      await apiClient.postJson<Map<String, dynamic>>(
        '/auth/logout',
        const {},
        (json) => json,
      );
    } catch (_) {
      // Ignora — o logout local já basta.
    }
  }
}
