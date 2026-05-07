import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../features/visitas/models/visita.dart';
import 'mock_database.dart';

/// Backend in-memory para o demo.
///
/// Substitua o `httpClientAdapter` do Dio:
/// ```dart
/// ArchbaseBootstrap.api.raw.httpClientAdapter = MockApiAdapter();
/// ```
///
/// Endpoints implementados:
/// - POST /auth/login            → token + user
/// - POST /auth/refresh          → novo token
/// - POST /auth/logout           → 200
/// - GET  /visitas?page=0&size=10&query=...
/// - GET  /visitas/{id}
/// - POST /visitas               (cria)
/// - PUT  /visitas/{id}          (atualiza)
/// - DELETE /visitas/{id}
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final ValueNotifier<bool> simulateOffline = ValueNotifier<bool>(false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);

    if (simulateOffline.value) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Sem conexão (modo offline simulado)',
      );
    }

    final method = options.method.toUpperCase();
    final path = options.path.startsWith('/')
        ? options.path
        : Uri.parse(options.uri.toString()).path;

    Map<String, dynamic>? body;
    if (options.data is Map) {
      body = (options.data as Map).cast<String, dynamic>();
    } else if (options.data is String && (options.data as String).isNotEmpty) {
      try {
        body = (jsonDecode(options.data as String) as Map)
            .cast<String, dynamic>();
      } catch (_) {}
    }

    return _handle(method, path, body, options);
  }

  Future<ResponseBody> _handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    RequestOptions options,
  ) async {
    // ---- Auth -----------------------------------------------------------
    if (method == 'POST' && path.endsWith('/auth/login')) {
      final username = body?['username']?.toString() ?? '';
      final password = body?['password']?.toString() ?? '';
      if (password.length < 4) {
        return _json(401, {'message': 'Credenciais inválidas'});
      }
      return _json(200, {
        'accessToken': 'demo-access-${DateTime.now().millisecondsSinceEpoch}',
        'refreshToken': 'demo-refresh',
        'expiresIn': 3600,
        'user': {
          'id': 'u-1',
          'displayName': username.split('@').first,
          'email': username,
          'roles': ['PROMOTOR'],
        },
      });
    }
    if (method == 'POST' && path.endsWith('/auth/refresh')) {
      return _json(200, {
        'accessToken': 'demo-access-${DateTime.now().millisecondsSinceEpoch}',
        'refreshToken': 'demo-refresh',
        'expiresIn': 3600,
      });
    }
    if (method == 'POST' && path.endsWith('/auth/logout')) {
      return _json(200, {'ok': true});
    }

    // ---- Visitas --------------------------------------------------------
    final db = MockDatabase.instance;

    if (method == 'GET' && path.endsWith('/visitas')) {
      final qp = options.queryParameters;
      final page = (qp['page'] as num?)?.toInt() ?? 0;
      final size = (qp['size'] as num?)?.toInt() ?? 10;
      final query = qp['query']?.toString();
      final paged = db.pageVisitas(page: page, size: size, query: query);
      return _json(200, {
        'content': paged.content.map((v) => v.toJson()).toList(),
        'totalElements': paged.totalElements,
        'totalPages': paged.totalPages,
        'number': paged.currentPage,
        'size': paged.pageSize,
        'first': paged.first,
        'last': paged.last,
      });
    }

    final visitaIdMatch = RegExp(r'/visitas/(.+)$').firstMatch(path);
    if (method == 'GET' && visitaIdMatch != null) {
      final v = db.visitas[visitaIdMatch.group(1)];
      if (v == null) return _json(404, {'message': 'Visita não encontrada'});
      return _json(200, v.toJson());
    }

    if (method == 'POST' && path.endsWith('/visitas')) {
      if (body == null) return _json(400, {'message': 'Payload vazio'});
      final pdvId = body['pdvId']?.toString();
      final pdv = db.pdvs[pdvId];
      if (pdv == null) return _json(400, {'message': 'PDV inválido'});
      final id = body['id']?.toString() ?? db.nextVisitaId();
      final v = Visita(
        id: id,
        pdv: pdv,
        status: _statusFromBody(body),
        dataAgendada:
            DateTime.tryParse(body['dataAgendada']?.toString() ?? '') ??
            DateTime.now(),
        observacao: body['observacao']?.toString(),
        fotoBase64: body['fotoBase64']?.toString(),
      );
      db.visitas[v.id] = v;
      return _json(201, v.toJson());
    }

    if (method == 'PUT' && visitaIdMatch != null) {
      final id = visitaIdMatch.group(1)!;
      final existing = db.visitas[id];
      if (existing == null) {
        return _json(404, {'message': 'Visita não encontrada'});
      }
      final updated = existing.copyWith(
        status: _statusFromBody(body, fallback: existing.status),
        dataAgendada: body == null
            ? existing.dataAgendada
            : DateTime.tryParse(body['dataAgendada']?.toString() ?? '') ??
                  existing.dataAgendada,
        observacao: body?['observacao']?.toString() ?? existing.observacao,
        fotoBase64: body?['fotoBase64']?.toString() ?? existing.fotoBase64,
        dataConclusao:
            (_statusFromBody(body, fallback: existing.status) ==
                VisitaStatus.concluida)
            ? DateTime.now()
            : existing.dataConclusao,
      );
      db.visitas[id] = updated;
      return _json(200, updated.toJson());
    }

    if (method == 'DELETE' && visitaIdMatch != null) {
      final id = visitaIdMatch.group(1)!;
      if (db.visitas.remove(id) == null) {
        return _json(404, {'message': 'Visita não encontrada'});
      }
      return _json(204, {});
    }

    // ---- PDVs (read-only) ----------------------------------------------
    if (method == 'GET' && path.endsWith('/pdvs')) {
      return _json(200, {
        'content': db.pdvs.values.map((p) => p.toJson()).toList(),
        'totalElements': db.pdvs.length,
        'totalPages': 1,
        'number': 0,
        'size': db.pdvs.length,
        'first': true,
        'last': true,
      });
    }

    return _json(404, {'message': 'Rota não encontrada: $method $path'});
  }

  VisitaStatus _statusFromBody(
    Map<String, dynamic>? body, {
    VisitaStatus fallback = VisitaStatus.planejada,
  }) {
    final raw = body?['status']?.toString();
    if (raw == null) return fallback;
    try {
      return VisitaStatus.values.firstWhere((s) => s.value == raw);
    } catch (_) {
      return fallback;
    }
  }

  ResponseBody _json(int status, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
