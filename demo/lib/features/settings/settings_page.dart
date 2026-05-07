import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../keys/test_keys.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.services,
    required this.onLogout,
  });

  final AppServices services;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return ArchbaseSettingsScreen(
      themeController: services.themeController,
      title: 'Configurações',
      appName: 'Archbase Demo',
      appVersion: '0.1.0',
      onLogout: onLogout,
      extraSections: [
        ArchbaseSettingsSection(
          title: 'Modo desenvolvedor',
          items: [
            ArchbaseSettingItem(
              icon: LucideIcons.wifiOff,
              title: 'Simular offline',
              subtitle:
                  'Liga/desliga o modo offline simulado pelo MockApiAdapter',
              trailing: ValueListenableBuilder<bool>(
                valueListenable: services.mockAdapter.simulateOffline,
                builder: (context, value, child) => Switch(
                  key: const ValueKey(TestKeys.devToggleOffline),
                  value: value,
                  onChanged: (v) {
                    services.mockAdapter.simulateOffline.value = v;
                    // Sincroniza connectivity service para o banner reagir.
                    final conn = ArchbaseBootstrap.connectivity;
                    conn.isConnected.value = !v;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
