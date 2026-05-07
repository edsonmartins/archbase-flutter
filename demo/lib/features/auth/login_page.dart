import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../home/home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ArchbaseLoginScreen(
      appName: 'Archbase Demo',
      tagline: 'Use senha com 4+ caracteres para entrar',
      versionLabel: 'v0.1.0',
      usernameValidator: ArchbaseValidators.compose([
        ArchbaseValidators.required,
        ArchbaseValidators.email,
      ]),
      devUsers: const [
        ArchbaseDevUser(
          label: 'Promotor',
          username: 'promotor@archbase.dev',
          password: 'archbase',
        ),
        ArchbaseDevUser(
          label: 'Admin',
          username: 'admin@archbase.dev',
          password: 'archbase',
        ),
      ],
      onLogin: (username, password, _) async {
        try {
          await services.auth.login({
            'username': username,
            'password': password,
          });
        } on AuthException catch (e) {
          return e.message;
        }
        if (!context.mounted) return null;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(services: services)),
        );
        return null;
      },
      onForgotPassword: () {
        ArchbaseAlertDialog.show(
          context,
          title: 'Recuperação de senha',
          message: 'Funcionalidade não implementada no demo.',
          severity: ArchbaseAlertSeverity.info,
        );
      },
    );
  }
}
