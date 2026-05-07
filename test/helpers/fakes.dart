import 'dart:async';

import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Fake do [ArchbaseConnectivityService] sem usar `connectivity_plus`.
///
/// Em testes, basta `setOnline(false)` para simular queda.
class FakeConnectivity extends ChangeNotifier
    implements ArchbaseConnectivityService {
  @override
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<ArchbaseConnectionType> connectionType =
      ValueNotifier<ArchbaseConnectionType>(ArchbaseConnectionType.wifi);

  final _connectedController = StreamController<void>.broadcast();
  final _disconnectedController = StreamController<void>.broadcast();

  @override
  Stream<void> get onConnected => _connectedController.stream;

  @override
  Stream<void> get onDisconnected => _disconnectedController.stream;

  void setOnline(bool online) {
    if (online == isConnected.value) return;
    isConnected.value = online;
    connectionType.value =
        online ? ArchbaseConnectionType.wifi : ArchbaseConnectionType.none;
    if (online) {
      _connectedController.add(null);
    } else {
      _disconnectedController.add(null);
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> onInit() async {}

  @override
  Future<void> onDispose() async {
    await _connectedController.close();
    await _disconnectedController.close();
  }

  @override
  bool get isReady => true;

  @override
  bool get isDisposed => false;

  @override
  void dispose() {
    onDispose();
    isConnected.dispose();
    connectionType.dispose();
    super.dispose();
  }
}

/// Auth service de teste com login determinístico.
class FakeArchbaseAuthService extends ArchbaseAuthService<SimpleArchbaseUser> {
  FakeArchbaseAuthService({
    required super.apiClient,
    required super.tokens,
    this.failOnLogin = false,
    this.failOnRefresh = false,
  }) : super(userFromJson: SimpleArchbaseUser.fromJson);

  bool failOnLogin;
  bool failOnRefresh;
  int loginCalls = 0;
  int refreshCalls = 0;
  int remoteLogoutCalls = 0;

  @override
  Future<ArchbaseLoginResult<SimpleArchbaseUser>> performLogin(
    Map<String, dynamic> credentials,
  ) async {
    loginCalls++;
    if (failOnLogin) throw InvalidCredentialsException();
    return ArchbaseLoginResult<SimpleArchbaseUser>(
      tokens: ArchbaseTokenSet(
        accessToken: 'tok-$loginCalls',
        refreshToken: 'ref-$loginCalls',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
      user: SimpleArchbaseUser(
        id: 'u-1',
        displayName: 'Test User',
        email: credentials['username']?.toString(),
        roles: const ['USER'],
      ),
    );
  }

  @override
  Future<ArchbaseTokenSet> performRefresh(String refreshToken) async {
    refreshCalls++;
    if (failOnRefresh) throw RefreshFailedException();
    return ArchbaseTokenSet(
      accessToken: 'tok-refreshed-$refreshCalls',
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> performRemoteLogout() async {
    remoteLogoutCalls++;
  }
}
