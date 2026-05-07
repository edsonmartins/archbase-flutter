import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../features/auth/demo_auth_service.dart';
import '../mock/mock_api_adapter.dart';
import '../mock/mock_database.dart';

class AppServices {
  AppServices({
    required this.auth,
    required this.themeController,
    required this.mockAdapter,
  });

  final DemoAuthService auth;
  final ArchbaseThemeController themeController;
  final MockApiAdapter mockAdapter;
}

/// Inicializa archbase + mock backend + auth + theme controller.
Future<AppServices> bootstrap() async {
  await ArchbaseBootstrap.init(
    config: const ArchbaseConfig(
      appName: 'Archbase Demo',
      appVersion: '0.1.0',
      currentEnv: ArchbaseEnv.dev,
      environments: {
        ArchbaseEnv.dev: 'http://mock.archbase/api/v1',
      },
      tenantId: 'demo',
    ),
  );

  // Substitui o adapter Dio por um mock in-memory.
  final mockAdapter = MockApiAdapter();
  ArchbaseBootstrap.api.raw.httpClientAdapter = mockAdapter;
  MockDatabase.instance.seed();

  final auth = DemoAuthService(
    apiClient: ArchbaseBootstrap.api,
    tokens: ArchbaseTokenHolder(ArchbaseBootstrap.storage),
  );
  await auth.init();
  ArchbaseBootstrap.setAuthService(auth);

  final themeController =
      ArchbaseThemeController(ArchbaseBootstrap.storage);
  await themeController.init();

  if (kDebugMode) {
    debugPrint('[demo] bootstrap concluído');
  }

  return AppServices(
    auth: auth,
    themeController: themeController,
    mockAdapter: mockAdapter,
  );
}
