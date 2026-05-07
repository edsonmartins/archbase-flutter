import 'package:uuid/uuid.dart';

/// Wrapper estático sobre `uuid` para evitar instância em cada call site.
class UuidUtils {
  UuidUtils._();

  static const _uuid = Uuid();

  static String v4() => _uuid.v4();
  static String v1() => _uuid.v1();
}
