import 'dart:io';

import 'package:hive/hive.dart';

/// Inicializa Hive em diretório temporário para testes. Use no `setUp`
/// e [closeHive] no `tearDown`.
Directory? _hiveDir;

Future<void> initHiveForTests() async {
  _hiveDir ??= await Directory.systemTemp.createTemp('archbase_hive_');
  Hive.init(_hiveDir!.path);
}

Future<void> closeHive() async {
  await Hive.close();
}

Future<void> resetHive() async {
  await Hive.deleteFromDisk();
}
