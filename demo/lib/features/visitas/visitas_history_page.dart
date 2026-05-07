import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../mock/mock_database.dart';
import 'models/visita.dart';

class VisitasHistoryPage extends StatelessWidget {
  const VisitasHistoryPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final concluidas = MockDatabase.instance.visitas.values
        .where((v) => v.status == VisitaStatus.concluida)
        .toList()
      ..sort(
        (a, b) =>
            (b.dataConclusao ?? b.dataAgendada)
                .compareTo(a.dataConclusao ?? a.dataAgendada),
      );

    return Scaffold(
      appBar: const ArchbaseAppBar(
        title: 'Histórico',
        subtitle: 'Visitas concluídas',
      ),
      body: concluidas.isEmpty
          ? const ArchbaseEmptyState(
              title: 'Nenhuma visita concluída',
              message: 'Quando você concluir visitas, elas aparecem aqui.',
              icon: LucideIcons.history,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: concluidas.length,
              itemBuilder: (context, idx) {
                final v = concluidas[idx];
                return ArchbaseCard(
                  leading: const Icon(LucideIcons.circleCheck,
                      color: Colors.green),
                  title: v.pdv.nome,
                  subtitle:
                      '${v.pdv.cidadeUf} · ${ArchbaseDateFormatter.relative(v.dataConclusao ?? v.dataAgendada)}',
                  body: v.observacao == null ? null : Text(v.observacao!),
                );
              },
            ),
    );
  }
}
