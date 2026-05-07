import 'package:archbase_flutter/archbase_flutter.dart';

import 'models/visita.dart';

/// Camada fina sobre o [ArchbaseApiClient] para visitas. Cuida de
/// serializar/deserializar e expor a paginação.
class VisitasRepository {
  VisitasRepository(this._api);

  final ArchbaseApiClient _api;

  Future<PaginatedResponse<Visita>> list({
    required int page,
    int size = 10,
    String? query,
  }) async {
    final response = await _api.getPaged<Visita>(
      '/visitas',
      Visita.fromJson,
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    return response.orThrow();
  }

  Future<Visita> create(Map<String, dynamic> payload) async {
    final response =
        await _api.postJson<Visita>('/visitas', payload, Visita.fromJson);
    return response.orThrow();
  }

  Future<Visita> update(String id, Map<String, dynamic> payload) async {
    final response =
        await _api.putJson<Visita>('/visitas/$id', payload, Visita.fromJson);
    return response.orThrow();
  }

  Future<void> delete(String id) async {
    final response = await _api.delete('/visitas/$id');
    response.orThrow();
  }
}
