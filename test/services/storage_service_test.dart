import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ArchbaseStorageService> newService() async {
    final s = ArchbaseStorageService();
    await s.init();
    return s;
  }

  group('ArchbaseStorageService — primitivos', () {
    test('write/read string', () async {
      final s = await newService();
      await s.write('k', 'v');
      expect(await s.read('k'), 'v');
    });

    test('writeBool/readBool', () async {
      final s = await newService();
      await s.writeBool('k', true);
      expect(await s.readBool('k'), isTrue);
    });

    test('writeInt/readInt', () async {
      final s = await newService();
      await s.writeInt('n', 42);
      expect(await s.readInt('n'), 42);
    });

    test('writeDouble/readDouble', () async {
      final s = await newService();
      await s.writeDouble('d', 3.14);
      expect(await s.readDouble('d'), 3.14);
    });

    test('writeDate/readDate é round-trip', () async {
      final s = await newService();
      final d = DateTime(2026, 5, 7, 14, 0);
      await s.writeDate('day', d);
      expect(await s.readDate('day'), d);
    });

    test('writeJson/readJson é round-trip', () async {
      final s = await newService();
      await s.writeJson('user', {'id': 1, 'nome': 'Edson'});
      expect(await s.readJson('user'), {'id': 1, 'nome': 'Edson'});
    });

    test('readJson devolve null em string inválida', () async {
      final s = await newService();
      await s.write('user', 'not-json');
      expect(await s.readJson('user'), isNull);
    });
  });

  group('ArchbaseStorageService — operações', () {
    test('contains/remove', () async {
      final s = await newService();
      await s.write('k', 'v');
      expect(await s.contains('k'), isTrue);
      await s.remove('k');
      expect(await s.read('k'), isNull);
    });

    test('clearAll limpa tudo', () async {
      final s = await newService();
      await s.write('a', '1');
      await s.write('b', '2');
      await s.clearAll();
      expect(await s.read('a'), isNull);
      expect(await s.read('b'), isNull);
    });

    test('notifica listeners em write', () async {
      final s = await newService();
      var notifications = 0;
      s.addListener(() => notifications++);
      await s.write('k', 'v');
      expect(notifications, 1);
    });
  });
}
