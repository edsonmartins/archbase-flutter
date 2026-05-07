import 'dart:convert';

/// Decoder mínimo de JWT (sem validar assinatura).
class JwtUtils {
  JwtUtils._();

  /// Decodifica o payload de um JWT. Retorna `null` se mal-formado.
  static Map<String, dynamic>? decode(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      return (jsonDecode(decoded) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  /// `exp` (Unix seconds) → DateTime. Null se ausente.
  static DateTime? expiresAt(String token) {
    final claims = decode(token);
    final exp = claims?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }

  static bool isExpired(String token, {Duration leeway = Duration.zero}) {
    final exp = expiresAt(token);
    if (exp == null) return false;
    return DateTime.now().toUtc().add(leeway).isAfter(exp);
  }

  static String? subject(String token) => decode(token)?['sub']?.toString();
}
