import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_controller.dart';
import '../../theme/archbase_theme_extensions.dart';
import '../../theme/archbase_text_styles.dart';
import '../../widgets/dialogs/archbase_confirm_dialog.dart';
import '../../widgets/layout/archbase_app_bar.dart';

class ArchbaseSettingItem {
  const ArchbaseSettingItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class ArchbaseSettingsSection {
  const ArchbaseSettingsSection({required this.title, required this.items});
  final String title;
  final List<ArchbaseSettingItem> items;
}

/// Tela de configurações com seções: tema, fonte, contraste, biometria,
/// notificações, sobre, logout. As seções extras são costumizáveis.
class ArchbaseSettingsScreen extends StatelessWidget {
  const ArchbaseSettingsScreen({
    super.key,
    required this.themeController,
    this.title = 'Configurações',
    this.appName,
    this.appVersion,
    this.onLogout,
    this.extraSections = const [],
  });

  final ArchbaseThemeController themeController;
  final String title;
  final String? appName;
  final String? appVersion;
  final Future<void> Function()? onLogout;
  final List<ArchbaseSettingsSection> extraSections;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return Scaffold(
          appBar: ArchbaseAppBar(title: title),
          body: ListView(
            children: [
              _section(
                context,
                title: 'Aparência',
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.sunMoon),
                    title: const Text('Tema'),
                    subtitle: Text(_themeLabel(themeController.themeMode)),
                    onTap: () => themeController.toggleThemeMode(),
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.aLargeSmall),
                    title: const Text('Tamanho da fonte'),
                    subtitle: Text(_fontLabel(themeController.fontScale)),
                    trailing: PopupMenuButton<ArchbaseFontScale>(
                      onSelected: themeController.setFontScale,
                      itemBuilder: (_) => ArchbaseFontScale.values
                          .map(
                            (s) => PopupMenuItem(
                              value: s,
                              child: Text(_fontLabel(s)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.contrast),
                    title: const Text('Alto contraste'),
                    value: themeController.highContrast,
                    onChanged: themeController.setHighContrast,
                  ),
                ],
              ),
              for (final extra in extraSections)
                _section(
                  context,
                  title: extra.title,
                  children: extra.items.map(_itemTile).toList(),
                ),
              if (onLogout != null)
                _section(
                  context,
                  title: 'Conta',
                  children: [
                    ListTile(
                      leading: Icon(LucideIcons.logOut,
                          color: context.archbaseColors.error),
                      title: Text(
                        'Sair',
                        style: TextStyle(color: context.archbaseColors.error),
                      ),
                      onTap: () async {
                        final ok = await ArchbaseConfirmDialog.show(
                          context,
                          title: 'Sair?',
                          message: 'Você precisará entrar novamente.',
                          confirmLabel: 'Sair',
                          destructive: true,
                          icon: LucideIcons.logOut,
                        );
                        if (ok) await onLogout!();
                      },
                    ),
                  ],
                ),
              if (appName != null || appVersion != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      [
                        if (appName != null) appName,
                        if (appVersion != null) 'v$appVersion',
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.archbase.textSecondary,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.archbase.textSecondary,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _itemTile(ArchbaseSettingItem item) {
    return Builder(
      builder: (context) => ListTile(
        leading: item.icon == null ? null : Icon(item.icon),
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        trailing: item.trailing,
        onTap: item.onTap,
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Padrão do sistema';
    }
  }

  String _fontLabel(ArchbaseFontScale scale) {
    switch (scale) {
      case ArchbaseFontScale.small:
        return 'Pequeno';
      case ArchbaseFontScale.normal:
        return 'Normal';
      case ArchbaseFontScale.large:
        return 'Grande';
      case ArchbaseFontScale.xlarge:
        return 'Muito grande';
    }
  }
}
