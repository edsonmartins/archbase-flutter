import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'fake_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ArchbaseBootstrap.init(
    config: const ArchbaseConfig(
      appName: 'Archbase Demo',
      appVersion: '0.1.0',
      currentEnv: ArchbaseEnv.dev,
      environments: {
        ArchbaseEnv.dev: 'https://api-dev.exemplo.com.br',
        ArchbaseEnv.prod: 'https://api.exemplo.com.br',
      },
      tenantId: 'demo',
      acceptSelfSignedCerts: true,
    ),
  );

  // Plug do AuthService: o app fornece, a lib usa via ArchbaseBootstrap.auth.
  final auth = FakeAuthService(
    apiClient: ArchbaseBootstrap.api,
    tokens: ArchbaseTokenHolder(ArchbaseBootstrap.storage),
  );
  await auth.init();
  ArchbaseBootstrap.setAuthService(auth);

  // Theme controller (não é criado pelo bootstrap por ser opcional).
  final themeController = ArchbaseThemeController(ArchbaseBootstrap.storage);
  await themeController.init();

  runApp(ArchbaseDemoApp(themeController: themeController, auth: auth));
}
