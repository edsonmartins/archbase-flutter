import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        theme: ArchbaseTheme.light(),
        home: child,
      );

  // `pumpAndSettle` não pode ser usado porque o `CircularProgressIndicator`
  // animaria indefinidamente. Bombamos frames manualmente.
  Future<void> tick(WidgetTester tester,
      [Duration step = const Duration(milliseconds: 20)]) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(step);
    }
  }

  group('ArchbaseSplashScreen', () {
    testWidgets('renderiza appName, tagline e versionLabel', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseSplashScreen(
            appName: 'Meu App',
            tagline: 'Vai de archbase',
            versionLabel: 'v1.2.3',
            bootstrap: () async => null,
            minimumDisplay: Duration.zero,
            onReady: (_, __) {},
          ),
        ),
      );
      expect(find.text('Meu App'), findsOneWidget);
      expect(find.text('Vai de archbase'), findsOneWidget);
      expect(find.text('v1.2.3'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tick(tester);
    });

    testWidgets('bootstrap success chama onReady com payload', (tester) async {
      Object? payload;
      await tester.pumpWidget(
        app(
          ArchbaseSplashScreen(
            bootstrap: () async => 'user-x',
            minimumDisplay: Duration.zero,
            onReady: (_, p) => payload = p,
          ),
        ),
      );
      await tick(tester);
      expect(payload, 'user-x');
    });

    testWidgets('bootstrap com erro dispara onError', (tester) async {
      Object? err;
      await tester.pumpWidget(
        app(
          ArchbaseSplashScreen(
            bootstrap: () async => throw StateError('boom'),
            minimumDisplay: Duration.zero,
            onReady: (_, __) {},
            onError: (_, e) => err = e,
          ),
        ),
      );
      await tick(tester);
      expect(err, isA<StateError>());
    });

    testWidgets('respeita minimumDisplay antes de chamar onReady',
        (tester) async {
      var ready = false;
      await tester.pumpWidget(
        app(
          ArchbaseSplashScreen(
            bootstrap: () async => null,
            minimumDisplay: const Duration(milliseconds: 300),
            onReady: (_, __) => ready = true,
          ),
        ),
      );
      // Após 50ms, bootstrap já voltou mas onReady ainda não.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(ready, isFalse);

      // Avança o suficiente para passar o minimumDisplay.
      await tester.pump(const Duration(milliseconds: 350));
      expect(ready, isTrue);
    });

    testWidgets('logo customizado substitui FlutterLogo', (tester) async {
      await tester.pumpWidget(
        app(
          ArchbaseSplashScreen(
            logo: const Icon(Icons.rocket, key: ValueKey('custom-logo')),
            bootstrap: () async => null,
            minimumDisplay: Duration.zero,
            onReady: (_, __) {},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('custom-logo')), findsOneWidget);
      expect(find.byType(FlutterLogo), findsNothing);
      await tick(tester);
    });
  });
}
