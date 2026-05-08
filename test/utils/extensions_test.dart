import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String extensions', () {
    test('isBlank/isNotBlank', () {
      expect('  '.isBlank, isTrue);
      expect('x'.isNotBlank, isTrue);
      expect(''.isBlank, isTrue);
    });
    test('capitalize / titleCase', () {
      expect('edson'.capitalize(), 'Edson');
      expect('edson martins'.titleCase(), 'Edson Martins');
      expect(''.capitalize(), '');
    });
    test('truncate', () {
      expect('archbase flutter'.truncate(8), 'archbase…');
      expect('curto'.truncate(10), 'curto');
    });
    test('onlyDigits / onlyAlphanumeric', () {
      expect('(11) 9.1234-5678'.onlyDigits(), '11912345678');
      expect('Edson #123!'.onlyAlphanumeric(), 'Edson 123');
    });
    test('toIntOrNull / toDoubleBrOrNull', () {
      expect('42'.toIntOrNull(), 42);
      expect('xyz'.toIntOrNull(), isNull);
      expect('1,5'.toDoubleBrOrNull(), 1.5);
      expect('abc'.toDoubleBrOrNull(), isNull);
    });
    test('initials', () {
      expect('Edson Martins'.initials(), 'EM');
      expect('edson'.initials(), 'E');
      expect(''.initials(), '');
      expect('A B C'.initials(max: 3), 'ABC');
    });
    test('mask', () {
      expect('1234567890'.mask(), '••••••7890');
      expect('123'.mask(visible: 4), '123');
    });
  });

  group('num extensions', () {
    test('isPositive / isNegative / isZero', () {
      expect(5.isPositive, isTrue);
      expect((-1).isNegative, isTrue);
      expect(0.isZero, isTrue);
    });
    test('clampTo', () {
      expect(15.clampTo(0, 10), 10);
      expect((-5).clampTo(0, 10), 0);
      expect(5.clampTo(0, 10), 5);
    });
  });

  group('DateTime extensions', () {
    test('isSameDay / startOfDay / endOfDay', () {
      final a = DateTime(2026, 5, 8, 14, 30);
      final b = DateTime(2026, 5, 8, 22, 0);
      expect(a.isSameDay(b), isTrue);
      expect(a.startOfDay.hour, 0);
      expect(a.endOfDay.hour, 23);
    });
    test('daysUntil', () {
      final a = DateTime(2026, 5, 1);
      final b = DateTime(2026, 5, 5);
      expect(a.daysUntil(b), 4);
      expect(b.daysUntil(a), -4);
    });
  });

  group('List/Iterable/Map extensions', () {
    test('tryGet', () {
      expect([1, 2, 3].tryGet(0), 1);
      expect([1, 2, 3].tryGet(5), isNull);
      expect([1, 2, 3].tryGet(-1), isNull);
    });
    test('chunked', () {
      expect([1, 2, 3, 4, 5].chunked(2), [
        [1, 2],
        [3, 4],
        [5],
      ]);
    });
    test('separatedBy', () {
      expect([1, 2, 3].separatedBy(0), [1, 0, 2, 0, 3]);
      expect([1].separatedBy(0), [1]);
    });
    test('firstWhereOrNull', () {
      expect([1, 2, 3].firstWhereOrNull((e) => e > 1), 2);
      expect([1, 2, 3].firstWhereOrNull((e) => e > 10), isNull);
    });
    test('Map.compact removes nulls', () {
      final m = <String, dynamic>{'a': 1, 'b': null, 'c': 'x'};
      expect(m.compact(), {'a': 1, 'c': 'x'});
    });
  });
}
