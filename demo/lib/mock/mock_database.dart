import 'package:archbase_flutter/archbase_flutter.dart';

import '../features/visitas/models/pdv.dart';
import '../features/visitas/models/visita.dart';

/// "Banco de dados" em memória usado pelo [MockApiAdapter].
///
/// Mantém PDVs (read-only) e Visitas (CRUD). Tudo é seedado no init().
class MockDatabase {
  MockDatabase._();

  static final MockDatabase instance = MockDatabase._();

  final Map<String, Pdv> pdvs = {};
  final Map<String, Visita> visitas = {};

  bool _seeded = false;

  void seed() {
    if (_seeded) return;
    _seedPdvs();
    _seedVisitas();
    _seeded = true;
  }

  void _seedPdvs() {
    final raw = [
      ('PDV-001', 'Mercado Bom Preço', 'Av. Paulista, 1500', 'São Paulo', 'SP',
          -23.561, -46.656),
      ('PDV-002', 'Supermercado Estrela', 'R. das Flores, 234', 'Rio de Janeiro', 'RJ',
          -22.971, -43.183),
      ('PDV-003', 'Atacadão Central', 'BR-101, km 23', 'Curitiba', 'PR',
          -25.4284, -49.2733),
      ('PDV-004', 'Mini Mercado Bairro', 'R. da Praia, 12', 'Florianópolis', 'SC',
          -27.595, -48.548),
      ('PDV-005', 'Hiper Maxi', 'Av. Brasil, 789', 'Belo Horizonte', 'MG',
          -19.916, -43.934),
      ('PDV-006', 'Padaria Aurora', 'R. das Acácias, 45', 'Porto Alegre', 'RS',
          -30.034, -51.217),
      ('PDV-007', 'Empório Verde', 'Av. Beira-Mar, 999', 'Recife', 'PE',
          -8.057, -34.882),
      ('PDV-008', 'Mercado da Vila', 'R. Vila Mariana, 100', 'São Paulo', 'SP',
          -23.589, -46.638),
      ('PDV-009', 'Big Mart', 'Rod. dos Bandeirantes, km 30', 'Campinas', 'SP',
          -22.907, -47.063),
      ('PDV-010', 'Atacado Sul', 'BR-116, km 220', 'Joinville', 'SC',
          -26.305, -48.846),
    ];
    for (final (id, nome, endereco, cidade, uf, lat, lng) in raw) {
      pdvs[id] = Pdv(
        id: id,
        nome: nome,
        endereco: endereco,
        cidade: cidade,
        uf: uf,
        latitude: lat,
        longitude: lng,
        responsavel: 'Gerente $id',
      );
    }
  }

  void _seedVisitas() {
    final now = DateTime.now();
    final list = [
      Visita(
        id: 'V-001',
        pdv: pdvs['PDV-001']!,
        status: VisitaStatus.planejada,
        dataAgendada: now.add(const Duration(hours: 4)),
      ),
      Visita(
        id: 'V-002',
        pdv: pdvs['PDV-002']!,
        status: VisitaStatus.planejada,
        dataAgendada: now.add(const Duration(days: 1)),
      ),
      Visita(
        id: 'V-003',
        pdv: pdvs['PDV-003']!,
        status: VisitaStatus.concluida,
        dataAgendada: now.subtract(const Duration(days: 1)),
        dataConclusao: now.subtract(const Duration(days: 1, hours: 2)),
        observacao: 'Reposição de produtos OK. Cliente satisfeito.',
      ),
      Visita(
        id: 'V-004',
        pdv: pdvs['PDV-004']!,
        status: VisitaStatus.planejada,
        dataAgendada: now.subtract(const Duration(hours: 2)), // atrasada
      ),
      Visita(
        id: 'V-005',
        pdv: pdvs['PDV-005']!,
        status: VisitaStatus.cancelada,
        dataAgendada: now.subtract(const Duration(days: 3)),
        observacao: 'Cliente fora.',
      ),
    ];
    for (final v in list) {
      visitas[v.id] = v;
    }
  }

  String nextVisitaId() {
    final nums = visitas.keys
        .map((k) => int.tryParse(k.replaceFirst('V-', '')) ?? 0)
        .toList()
      ..sort();
    final next = (nums.isEmpty ? 0 : nums.last) + 1;
    return 'V-${next.toString().padLeft(3, '0')}';
  }

  PaginatedResponse<Visita> pageVisitas({
    required int page,
    int size = 10,
    String? query,
  }) {
    var all = visitas.values.toList()
      ..sort((a, b) => b.dataAgendada.compareTo(a.dataAgendada));
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      all = all
          .where((v) =>
              v.pdv.nome.toLowerCase().contains(q) ||
              v.pdv.cidade.toLowerCase().contains(q) ||
              v.id.toLowerCase().contains(q))
          .toList();
    }
    final start = (page * size).clamp(0, all.length);
    final end = (start + size).clamp(0, all.length);
    return PaginatedResponse<Visita>(
      content: all.sublist(start, end),
      totalElements: all.length,
      totalPages: (all.length / size).ceil().clamp(1, 9999),
      currentPage: page,
      pageSize: size,
      first: page == 0,
      last: end >= all.length,
    );
  }
}
