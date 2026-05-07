import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import 'fake_auth_service.dart';
import 'home_page.dart';

class ArchbaseDemoApp extends StatelessWidget {
  const ArchbaseDemoApp({
    super.key,
    required this.themeController,
    required this.auth,
  });

  final ArchbaseThemeController themeController;
  final FakeAuthService auth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Archbase Demo',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: ArchbaseTheme.light(
            fontScale: themeController.fontScale,
            highContrast: themeController.highContrast,
          ),
          darkTheme: ArchbaseTheme.dark(
            fontScale: themeController.fontScale,
            highContrast: themeController.highContrast,
          ),
          home: ValueListenableBuilder<bool>(
            valueListenable: auth.isAuthenticated,
            builder: (_, signed, __) {
              if (signed) {
                return HomePage(
                  themeController: themeController,
                  auth: auth,
                );
              }
              return ArchbaseLoginScreen(
                appName: 'Archbase Demo',
                tagline: 'Framework Flutter da família Archbase',
                versionLabel: 'v0.1.0',
                devUsers: const [
                  ArchbaseDevUser(
                    label: 'Admin',
                    username: 'admin@archbase.dev',
                    password: 'archbase',
                  ),
                  ArchbaseDevUser(
                    label: 'Usuário comum',
                    username: 'user@archbase.dev',
                    password: 'archbase',
                  ),
                ],
                onLogin: (username, password, remember) async {
                  try {
                    await auth.login({
                      'username': username,
                      'password': password,
                    });
                    return null;
                  } on AuthException catch (e) {
                    return e.message;
                  }
                },
                onForgotPassword: () {},
              );
            },
          ),
        );
      },
    );
  }
}
