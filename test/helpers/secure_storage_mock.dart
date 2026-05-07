import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registra um handler in-memory para o `MethodChannel` do
/// `flutter_secure_storage`. Use em `setUp`.
void mockSecureStorage() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          final key = call.arguments['key'] as String;
          return store[key];
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          if (value == null) {
            store.remove(key);
          } else {
            store[key] = value;
          }
          return null;
        case 'delete':
          final key = call.arguments['key'] as String;
          store.remove(key);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'containsKey':
          final key = call.arguments['key'] as String;
          return store.containsKey(key);
        default:
          return null;
      }
    },
  );
}
