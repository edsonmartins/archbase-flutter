import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:archbase_flutter/src/cli/casing.dart';
import 'package:archbase_flutter/src/cli/feature_scaffold.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>(
    'archbase',
    'CLI da archbase_flutter — gera scaffolds de feature, controllers e telas.',
  )..addCommand(FeatureCommand());

  try {
    final code = await runner.run(args) ?? 0;
    exit(code);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}

class FeatureCommand extends Command<int> {
  FeatureCommand() {
    argParser
      ..addOption(
        'root',
        abbr: 'r',
        help: 'Diretório raiz do app (default: lib).',
        defaultsTo: 'lib',
      )
      ..addOption(
        'endpoint',
        abbr: 'e',
        help: 'Endpoint REST (default: /<snake>s).',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Sobrescreve arquivos existentes.',
        negatable: false,
      );
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Cria scaffold completo de uma feature CRUD '
      '(model + repository + controller + 3 telas).';

  @override
  String get invocation => 'archbase feature <nome> [opções]';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const [];
    if (rest.isEmpty) {
      usageException('Nome da feature obrigatório.');
    }
    if (rest.length > 1) {
      usageException('Passe apenas um nome (use kebab/snake/camel/pascal).');
    }

    final name = rest.single;
    final root = argResults!['root'] as String;
    final endpoint = argResults!['endpoint'] as String?;
    final force = argResults!['force'] as bool;

    if (!Directory(root).existsSync()) {
      stderr.writeln('Diretório "$root" não existe.');
      return 1;
    }

    final scaffold = FeatureScaffold(
      name: name,
      targetRoot: root,
      endpoint: endpoint,
      overwrite: force,
    );

    try {
      final result = scaffold.run();
      stdout.writeln('✓ Feature "${Casing.snake(name)}" gerada em '
          '${result.basePath}\n');
      for (final f in result.files) {
        stdout.writeln('  + $f');
      }
      stdout
        ..writeln('\nPróximos passos:')
        ..writeln(
            '  1. Ajuste o model em ${result.basePath}/models/${Casing.snake(name)}.dart')
        ..writeln(
            '  2. Plug a rota da ${Casing.pascal(name)}ListPage no seu router')
        ..writeln(
            '  3. (opcional) Crie um provider Riverpod/Get binding pro controller');
      return 0;
    } on StateError catch (e) {
      stderr.writeln(e.message);
      return 1;
    }
  }
}
