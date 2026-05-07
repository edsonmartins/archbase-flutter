import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  Future<PaginatedResponse<int>> loadEmpty({
    required int page,
    required String? query,
    Map<String, dynamic>? filters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return PaginatedResponse.empty<int>();
  }

  Future<PaginatedResponse<int>> loadFull({
    required int page,
    required String? query,
    Map<String, dynamic>? filters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return PaginatedResponse<int>(
      content: const [10, 20, 30],
      totalElements: 3,
      totalPages: 1,
      currentPage: 0,
      pageSize: 3,
      first: true,
      last: true,
    );
  }

  Future<PaginatedResponse<int>> loadFails({
    required int page,
    required String? query,
    Map<String, dynamic>? filters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    throw Exception('Backend caiu');
  }

  group('ArchbaseCrudListScreen', () {
    testWidgets('passa por loading e cai em empty state', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCrudListScreen<int>(
            title: 'Itens',
            loader: loadEmpty,
            emptyTitle: 'Sem dados',
            itemBuilder: (_, item, __) => ListTile(title: Text('$item')),
          ),
        ),
      );
      // Loading: shimmer ou progress.
      await tester.pump();
      // Aguarda carregar.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('Sem dados'), findsOneWidget);
    });

    testWidgets('renderiza items quando carrega com sucesso', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCrudListScreen<int>(
            title: 'Itens',
            loader: loadFull,
            itemBuilder: (_, item, __) => ListTile(title: Text('Item $item')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 10'), findsOneWidget);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 30'), findsOneWidget);
    });

    testWidgets('exibe error view com retry quando loader falha',
        (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCrudListScreen<int>(
            title: 'Itens',
            loader: loadFails,
            itemBuilder: (_, item, __) => Text('$item'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Backend caiu'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('FAB de criar dispara onCreate', (tester) async {
      var created = false;
      await tester.pumpWidget(
        TestApp(
          child: ArchbaseCrudListScreen<int>(
            title: 'Itens',
            loader: loadEmpty,
            onCreate: () => created = true,
            itemBuilder: (_, item, __) => Text('$item'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(created, isTrue);
    });
  });
}
