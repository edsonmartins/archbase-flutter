import 'dart:convert';

import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

String _b64(Map<String, dynamic> obj) {
  final raw = base64.encode(utf8.encode(jsonEncode(obj)));
  // remove padding pra ficar igual a JWTs reais
  return raw.replaceAll('=', '');
}

String _fakeJwt(Map<String, dynamic> claims) {
  final header = _b64({'alg': 'none', 'typ': 'JWT'});
  final payload = _b64(claims);
  return '$header.$payload.';
}

void main() {
  group('JwtUtils', () {
    test('decode devolve claims', () {
      final token = _fakeJwt({'sub': 'u1', 'name': 'Edson'});
      final claims = JwtUtils.decode(token);
      expect(claims, isNotNull);
      expect(claims!['sub'], 'u1');
      expect(claims['name'], 'Edson');
    });

    test('decode em token mal-formado retorna null', () {
      expect(JwtUtils.decode('xpto'), isNull);
      expect(JwtUtils.decode('a.b'), isNull); // payload não-base64
      expect(JwtUtils.decode('só-uma-parte'), isNull);
    });

    test('expiresAt converte exp em DateTime UTC', () {
      final token = _fakeJwt({'exp': 1700000000});
      final dt = JwtUtils.expiresAt(token);
      expect(dt?.toUtc().year, 2023);
    });

    test('isExpired true quando exp já passou', () {
      final past = DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      expect(JwtUtils.isExpired(_fakeJwt({'exp': past})), isTrue);
    });

    test('isExpired false quando exp ainda no futuro', () {
      final future =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000;
      expect(JwtUtils.isExpired(_fakeJwt({'exp': future})), isFalse);
    });

    test('subject lê claim sub', () {
      expect(JwtUtils.subject(_fakeJwt({'sub': 'u-1'})), 'u-1');
    });
  });
}
