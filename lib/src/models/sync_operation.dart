/// Verbos suportados na fila de sincronização.
enum SyncMethod { get, post, put, patch, delete }

/// Uma operação enfileirada para envio futuro à API.
class SyncOperation {
  SyncOperation({
    required this.id,
    required this.method,
    required this.path,
    this.payload,
    this.headers,
    this.queryParams,
    this.tag,
    DateTime? createdAt,
    this.retries = 0,
    this.lastError,
    this.lastTriedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Id único, idealmente UUID.
  final String id;
  final SyncMethod method;
  final String path;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? queryParams;

  /// Tag livre para o app saber qual feature originou (ex.: 'visita',
  /// 'checkin'). Útil para mostrar progresso por feature na UI.
  final String? tag;

  final DateTime createdAt;

  int retries;
  String? lastError;
  DateTime? lastTriedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method.name,
        'path': path,
        'payload': payload,
        'headers': headers,
        'queryParams': queryParams,
        'tag': tag,
        'createdAt': createdAt.toIso8601String(),
        'retries': retries,
        'lastError': lastError,
        'lastTriedAt': lastTriedAt?.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      method: SyncMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => SyncMethod.post,
      ),
      path: json['path'] as String,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
      headers: (json['headers'] as Map?)?.cast<String, dynamic>(),
      queryParams: (json['queryParams'] as Map?)?.cast<String, dynamic>(),
      tag: json['tag'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retries: (json['retries'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
      lastTriedAt: json['lastTriedAt'] != null
          ? DateTime.tryParse(json['lastTriedAt'].toString())
          : null,
    );
  }
}
