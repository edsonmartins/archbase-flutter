import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ArchbaseSplashScreen(
      appName: 'Archbase Demo',
      tagline: 'Visitas a PDVs com offline-first',
      versionLabel: 'v0.1.0',
      bootstrap: () async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return services.auth.isAuthenticated.value;
      },
      onReady: (context, payload) {
        final loggedIn = payload == true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => loggedIn
                ? HomePage(services: services)
                : LoginPage(services: services),
          ),
        );
      },
    );
  }
}
