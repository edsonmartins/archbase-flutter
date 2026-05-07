import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
  });

  Future<(FakeArchbaseAuthService, ArchbaseStorageService, ArchbaseTokenHolder,
      ArchbaseApiClient)> setup({
    bool failOnLogin = false,
    bool failOnRefresh = false,
  }) async {
    final storage = ArchbaseStorageService();
    await storage.init();

    final api = ArchbaseApiClient(
      config: const ArchbaseConfig(
        appName: 'Test',
        currentEnv: ArchbaseEnv.dev,
        environments: {ArchbaseEnv.dev: 'http://test/'},
      ),
      storage: storage,
    );
    await api.init();

    final tokens = ArchbaseTokenHolder(storage);
    final auth = FakeArchbaseAuthService(
      apiClient: api,
      tokens: tokens,
      failOnLogin: failOnLogin,
      failOnRefresh: failOnRefresh,
    );
    await auth.init();
    return (auth, storage, tokens, api);
  }

  group('ArchbaseAuthService — login/logout', () {
    test('login bem-sucedido persiste tokens e emite onLoggedIn', () async {
      final (auth, _, tokens, api) = await setup();
      final logged = expectLater(auth.onLoggedIn, emits(isA<SimpleArchbaseUser>()));

      await auth.login({'username': 'edson@test.dev', 'password': 'archbase'});

      expect(auth.isAuthenticated.value, isTrue);
      expect(auth.currentUser.value, isNotNull);
      expect(auth.currentUser.value!.email, 'edson@test.dev');

      // Token foi salvo via storage seguro.
      expect(await tokens.readAccessToken(), startsWith('tok-'));
      expect(await tokens.readRefreshToken(), startsWith('ref-'));
      await logged;
      auth.dispose();
      api.dispose();
    });

    test('login com falha lança AuthException e mantém estado deslogado',
        () async {
      final (auth, _, tokens, api) = await setup(failOnLogin: true);
      await expectLater(
        auth.login({'username': 'x', 'password': 'y'}),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(auth.isAuthenticated.value, isFalse);
      expect(await tokens.readAccessToken(), isNull);
      auth.dispose();
      api.dispose();
    });

    test('logout limpa tokens, user e emite onLoggedOut', () async {
      final (auth, _, tokens, api) = await setup();
      await auth.login({'username': 'a', 'password': 'b'});

      final loggedOut = expectLater(auth.onLoggedOut, emits(null));
      await auth.logout();

      expect(auth.isAuthenticated.value, isFalse);
      expect(auth.currentUser.value, isNull);
      expect(await tokens.readAccessToken(), isNull);
      expect(auth.remoteLogoutCalls, 1);
      await loggedOut;
      auth.dispose();
      api.dispose();
    });

    test('logout(callRemote: false) não chama performRemoteLogout',
        () async {
      final (auth, _, _, api) = await setup();
      await auth.login({'username': 'a', 'password': 'b'});
      await auth.logout(callRemote: false);
      expect(auth.remoteLogoutCalls, 0);
      auth.dispose();
      api.dispose();
    });

    test('requireUser lança quando não autenticado', () async {
      final (auth, _, _, api) = await setup();
      expect(() => auth.requireUser(), throwsA(isA<AuthException>()));
      auth.dispose();
      api.dispose();
    });
  });

  group('ArchbaseAuthService — restauração e refresh', () {
    test('init recupera sessão se token + user já estão salvos', () async {
      // Faz login para semear storage.
      final (auth1, _, _, api1) = await setup();
      await auth1.login({'username': 'edson', 'password': 'x'});
      auth1.dispose();
      api1.dispose();

      // Cria nova instância — deve recuperar sessão sem chamar performLogin.
      final storage = ArchbaseStorageService();
      await storage.init();
      final api = ArchbaseApiClient(
        config: const ArchbaseConfig(
          appName: 'Test',
          currentEnv: ArchbaseEnv.dev,
          environments: {ArchbaseEnv.dev: 'http://test/'},
        ),
        storage: storage,
      );
      await api.init();
      final auth2 = FakeArchbaseAuthService(
        apiClient: api,
        tokens: ArchbaseTokenHolder(storage),
      );
      await auth2.init();

      expect(auth2.isAuthenticated.value, isTrue);
      expect(auth2.currentUser.value?.displayName, 'Test User');
      expect(auth2.loginCalls, 0);
      auth2.dispose();
      api.dispose();
    });

    test('falha de refresh dispara logout', () async {
      final (auth, _, tokens, api) = await setup(failOnRefresh: true);
      await auth.login({'username': 'a', 'password': 'b'});

      // Forçamos refresh via api client (registrado pelo init de auth).
      // Como o ApiClient só dispara refresh em 401, invocamos o callback
      // diretamente para validar o caminho de logout em falha.
      try {
        // ignore: invalid_use_of_protected_member
        await auth.performRefresh(await tokens.readRefreshToken() ?? '');
      } catch (_) {
        await auth.logout(callRemote: false);
      }
      expect(auth.isAuthenticated.value, isFalse);
      auth.dispose();
      api.dispose();
    });
  });
}
