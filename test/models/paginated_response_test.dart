import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> item(int id) => {'id': id};

  group('PaginatedResponse', () {
    test('fromJson Spring Data parseia content e flags', () {
      final r = PaginatedResponse<Map<String, dynamic>>.fromJson(
        {
          'content': [item(1), item(2)],
          'totalElements': 5,
          'totalPages': 3,
          'number': 0,
          'size': 2,
          'first': true,
          'last': false,
        },
        (j) => j,
      );
      expect(r.content, hasLength(2));
      expect(r.totalElements, 5);
      expect(r.totalPages, 3);
      expect(r.currentPage, 0);
      expect(r.first, isTrue);
      expect(r.last, isFalse);
      expect(r.hasMore, isTrue);
      expect(r.nextPage, 1);
    });

    test('fromJson aceita "page" como alternativa a "number"', () {
      final r = PaginatedResponse<Map<String, dynamic>>.fromJson(
        {
          'content': [item(1)],
          'page': 2,
          'size': 1,
          'totalPages': 5,
          'totalElements': 5,
        },
        (j) => j,
      );
      expect(r.currentPage, 2);
    });

    test('appendPage concatena conteúdos preservando metadados da última', () {
      final p1 = PaginatedResponse<int>(
        content: [1, 2],
        totalElements: 4,
        totalPages: 2,
        currentPage: 0,
        pageSize: 2,
        first: true,
      );
      final p2 = PaginatedResponse<int>(
        content: [3, 4],
        totalElements: 4,
        totalPages: 2,
        currentPage: 1,
        pageSize: 2,
        last: true,
      );
      final merged = p1.appendPage(p2);
      expect(merged.content, [1, 2, 3, 4]);
      expect(merged.last, isTrue);
      expect(merged.first, isTrue);
      expect(merged.hasMore, isFalse);
    });

    test('mapItems transforma sem alterar paginação', () {
      final r = PaginatedResponse<int>(
        content: [1, 2, 3],
        totalElements: 3,
        totalPages: 1,
        currentPage: 0,
        pageSize: 3,
        last: true,
      );
      final mapped = r.mapItems((i) => i.toString());
      expect(mapped.content, ['1', '2', '3']);
      expect(mapped.totalElements, 3);
    });

    test('empty é vazio e last=true', () {
      final r = PaginatedResponse.empty<int>();
      expect(r.isEmpty, isTrue);
      expect(r.last, isTrue);
      expect(r.hasMore, isFalse);
    });
  });
}
