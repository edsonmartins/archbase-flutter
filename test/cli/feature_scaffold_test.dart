import 'dart:io';

import 'package:archbase_flutter/src/cli/feature_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('archbase_scaffold_test_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  String inLib(String relative) => p.join(tempRoot.path, 'lib', relative);

  test('gera estrutura completa para uma feature simples', () {
    Directory(p.join(tempRoot.path, 'lib')).createSync(recursive: true);

    final result = FeatureScaffold(
      name: 'cliente',
      targetRoot: p.join(tempRoot.path, 'lib'),
    ).run();

    expect(result.basePath, inLib('features/cliente'));
    expect(result.files, hasLength(6));

    for (final f in result.files) {
      expect(File(f).existsSync(), isTrue, reason: 'arquivo ausente: $f');
    }

    final model =
        File(inLib('features/cliente/models/cliente.dart')).readAsStringSync();
    expect(model, contains('class Cliente implements BaseDto'));
    expect(model, contains('enum ClienteStatus with LabeledEnum'));

    final repo = File(inLib('features/cliente/cliente_repository.dart'))
        .readAsStringSync();
    expect(repo, contains('class ClienteRepository'));
    expect(repo, contains("'/clientes'"));
  });

  test('endpoint customizado é refletido no repository', () {
    Directory(p.join(tempRoot.path, 'lib')).createSync(recursive: true);

    FeatureScaffold(
      name: 'pdv',
      targetRoot: p.join(tempRoot.path, 'lib'),
      endpoint: '/api/v2/points-of-sale',
    ).run();

    final repo =
        File(inLib('features/pdv/pdv_repository.dart')).readAsStringSync();
    expect(repo, contains("'/api/v2/points-of-sale'"));
  });

  test('aceita kebab/PascalCase e normaliza nomes', () {
    Directory(p.join(tempRoot.path, 'lib')).createSync(recursive: true);

    final result = FeatureScaffold(
      name: 'PointOfSale',
      targetRoot: p.join(tempRoot.path, 'lib'),
    ).run();

    expect(result.basePath, inLib('features/point_of_sale'));
    expect(
      result.files,
      contains(inLib('features/point_of_sale/point_of_sale_controller.dart')),
    );

    final controller =
        File(inLib('features/point_of_sale/point_of_sale_controller.dart'))
            .readAsStringSync();
    expect(controller, contains('class PointOfSaleController'));
    expect(controller, contains('class PointOfSaleState'));
  });

  test('falha se arquivos já existem e overwrite=false', () {
    Directory(p.join(tempRoot.path, 'lib')).createSync(recursive: true);
    final scaffold = FeatureScaffold(
      name: 'dup',
      targetRoot: p.join(tempRoot.path, 'lib'),
    );

    scaffold.run();

    expect(
      () => scaffold.run(),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('já existem'),
      )),
    );
  });

  test('overwrite=true substitui sem erro', () {
    Directory(p.join(tempRoot.path, 'lib')).createSync(recursive: true);

    FeatureScaffold(
      name: 'dup',
      targetRoot: p.join(tempRoot.path, 'lib'),
    ).run();

    expect(
      () => FeatureScaffold(
        name: 'dup',
        targetRoot: p.join(tempRoot.path, 'lib'),
        overwrite: true,
      ).run(),
      returnsNormally,
    );
  });
}
