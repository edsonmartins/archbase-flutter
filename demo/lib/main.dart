import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap.dart';
import 'features/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await bootstrap();
  runApp(ArchbaseDemoApp(services: services));
}

class ArchbaseDemoApp extends StatelessWidget {
  const ArchbaseDemoApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Archbase Demo',
          debugShowCheckedModeBanner: false,
          themeMode: services.themeController.themeMode,
          theme: ArchbaseTheme.light(
            fontScale: services.themeController.fontScale,
            highContrast: services.themeController.highContrast,
          ),
          darkTheme: ArchbaseTheme.dark(
            fontScale: services.themeController.fontScale,
            highContrast: services.themeController.highContrast,
          ),
          home: SplashPage(services: services),
        );
      },
    );
  }
}
