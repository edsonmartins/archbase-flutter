import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/secure_storage_mock.dart';

void main() {
  late ArchbaseThemeController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final storage = ArchbaseStorageService();
    await storage.init();
    controller = ArchbaseThemeController(storage);
    await controller.init();
  });

  Widget app(Widget child) => MaterialApp(
        theme: ArchbaseTheme.light(),
        home: child,
      );

  group('ArchbaseSettingsScreen', () {
    testWidgets('renderiza seção Aparência com tema, fonte e contraste',
        (tester) async {
      await tester.pumpWidget(
        app(ArchbaseSettingsScreen(themeController: controller)),
      );
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('APARÊNCIA'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Tamanho da fonte'), findsOneWidget);
      expect(find.text('Alto contraste'), findsOneWidget);
    });

    testWidgets('tocar em Tema cicla o themeMode', (tester) async {
      await tester.pumpWidget(
        app(ArchbaseSettingsScreen(themeController: controller)),
      );
      expect(controller.themeMode, ThemeMode.system);

      await tester.tap(find.text('Tema'));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.light);

      await tester.tap(find.text('Tema'));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.dark);
    });

    testWidgets('SwitchListTile de contraste reflete o estado', (tester) async {
      await tester.pumpWidget(
        app(ArchbaseSettingsScreen(themeController: controller)),
      );
      final sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(controller.highContrast, isTrue);
    });

    testWidgets('onLogout exibe seção Conta e dispara após confirmação',
        (tester) async {
      var loggedOut = false;
      await tester.pumpWidget(
        app(
          ArchbaseSettingsScreen(
            themeController: controller,
            onLogout: () async => loggedOut = true,
          ),
        ),
      );
      expect(find.text('CONTA'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('Sair?'), findsOneWidget);

      // Cancela primeiro
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(loggedOut, isFalse);

      // Confirma
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      // Há "Sair" no ListTile e no botão de confirmação do dialog — pega
      // o do dialog (último).
      await tester.tap(find.text('Sair').last);
      await tester.pumpAndSettle();
      expect(loggedOut, isTrue);
    });

    testWidgets('appName + appVersion exibe rodapé', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseSettingsScreen(
            themeController: controller,
            appName: 'Meu App',
            appVersion: '1.2.3',
          ),
        ),
      );
      expect(find.text('Meu App · v1.2.3'), findsOneWidget);
    });

    testWidgets('extraSections são renderizadas', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseSettingsScreen(
            themeController: controller,
            extraSections: const [
              ArchbaseSettingsSection(
                title: 'Notificações',
                items: [
                  ArchbaseSettingItem(title: 'Push', subtitle: 'Ativado'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('NOTIFICAÇÕES'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
      expect(find.text('Ativado'), findsOneWidget);
    });
  });
}
