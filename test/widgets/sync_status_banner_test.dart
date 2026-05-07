import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('ArchbaseSyncStatusBanner.fromListenables', () {
    testWidgets('oculto quando online e sem pendências', (tester) async {
      final online = ValueNotifier<bool>(true);
      final status = ValueNotifier<ArchbaseSyncStatus>(
        const ArchbaseSyncStatus(),
      );
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
          ),
        ),
      );
      expect(find.textContaining('alterações'), findsNothing);
      expect(find.textContaining('conexão'), findsNothing);
    });

    testWidgets('mostra "Sem conexão" quando offline e sem pendências',
        (tester) async {
      final online = ValueNotifier<bool>(false);
      final status = ValueNotifier<ArchbaseSyncStatus>(
        const ArchbaseSyncStatus(),
      );
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
          ),
        ),
      );
      expect(find.text('Sem conexão'), findsOneWidget);
    });

    testWidgets('exibe contador de pendentes quando offline com fila',
        (tester) async {
      final online = ValueNotifier<bool>(false);
      final status = ValueNotifier<ArchbaseSyncStatus>(
          const ArchbaseSyncStatus(pending: 3));
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
          ),
        ),
      );
      expect(find.textContaining('3 alterações'), findsOneWidget);
    });

    testWidgets('exibe "Sincronizando" quando isSyncing=true', (tester) async {
      final online = ValueNotifier<bool>(true);
      final status = ValueNotifier<ArchbaseSyncStatus>(
        const ArchbaseSyncStatus(isSyncing: true, pending: 5),
      );
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
          ),
        ),
      );
      expect(find.textContaining('Sincronizando'), findsOneWidget);
    });

    testWidgets('reage à mudança de status', (tester) async {
      final online = ValueNotifier<bool>(false);
      final status = ValueNotifier<ArchbaseSyncStatus>(
        const ArchbaseSyncStatus(),
      );
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
          ),
        ),
      );
      expect(find.text('Sem conexão'), findsOneWidget);

      online.value = true;
      await tester.pump();
      expect(find.text('Sem conexão'), findsNothing);
      expect(find.textContaining('alterações'), findsNothing);
    });

    testWidgets('onTap dispara callback', (tester) async {
      var tapped = false;
      final online = ValueNotifier<bool>(false);
      final status = ValueNotifier<ArchbaseSyncStatus>(
        const ArchbaseSyncStatus(pending: 1),
      );
      addTearDown(() {
        online.dispose();
        status.dispose();
      });

      await tester.pumpWidget(
        TestApp(
          child: ArchbaseSyncStatusBanner.fromListenables(
            status: status,
            online: online,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
