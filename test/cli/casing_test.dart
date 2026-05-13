import 'package:archbase_flutter/src/cli/casing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Casing', () {
    test('snake — quebra camelCase, PascalCase, kebab, snake', () {
      expect(Casing.snake('myFeature'), 'my_feature');
      expect(Casing.snake('MyFeature'), 'my_feature');
      expect(Casing.snake('my-feature'), 'my_feature');
      expect(Casing.snake('my_feature'), 'my_feature');
      expect(Casing.snake('My Feature'), 'my_feature');
    });

    test('pascal', () {
      expect(Casing.pascal('my_feature'), 'MyFeature');
      expect(Casing.pascal('my-feature'), 'MyFeature');
      expect(Casing.pascal('myFeature'), 'MyFeature');
      expect(Casing.pascal('my feature'), 'MyFeature');
    });

    test('camel', () {
      expect(Casing.camel('my_feature'), 'myFeature');
      expect(Casing.camel('MyFeature'), 'myFeature');
      expect(Casing.camel('my-feature'), 'myFeature');
    });

    test('kebab', () {
      expect(Casing.kebab('myFeature'), 'my-feature');
      expect(Casing.kebab('my_feature'), 'my-feature');
    });

    test('human — primeira letra de cada palavra em maiúscula', () {
      expect(Casing.human('my_feature'), 'My Feature');
      expect(Casing.human('userProfile'), 'User Profile');
    });

    test('preserva acrônimos como uma única palavra ao quebrar', () {
      expect(Casing.snake('APIClient'), 'api_client');
      expect(Casing.pascal('api-client'), 'ApiClient');
    });

    test('input vazio retorna vazio', () {
      expect(Casing.snake(''), '');
      expect(Casing.pascal(''), '');
    });
  });
}
