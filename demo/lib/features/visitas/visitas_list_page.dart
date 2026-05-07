import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../keys/test_keys.dart';
import 'models/visita.dart';
import 'visita_form_page.dart';
import 'visitas_repository.dart';

class VisitasListPage extends StatelessWidget {
  const VisitasListPage({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final repo = VisitasRepository(ArchbaseBootstrap.api);

    return Column(
      children: [
        ArchbaseSyncStatusBanner(
          key: const ValueKey(TestKeys.syncBanner),
          queue: ArchbaseBootstrap.syncQueue,
          connectivity: ArchbaseBootstrap.connectivity,
        ),
        Expanded(
          child: ArchbaseCrudListScreen<Visita>(
            key: const ValueKey(TestKeys.visitasList),
            title: 'Visitas',
            subtitle: 'Olá, ${services.auth.currentUser.value?.displayName}',
            loader: ({required page, required query, filters}) {
              return repo.list(page: page, query: query);
            },
            onCreate: () => _openForm(context, services),
            onItemTap: (v) => _openForm(context, services, existing: v),
            itemBuilder: (context, v, idx) => _VisitaCard(visita: v, index: idx),
            emptyTitle: 'Nenhuma visita',
            emptyMessage: 'Toque no + para criar a primeira',
            searchHint: 'Buscar por PDV, cidade ou ID…',
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    AppServices services, {
    Visita? existing,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitaFormPage(services: services, existing: existing),
      ),
    );
    if (saved == true && context.mounted) {
      // Sinaliza para o list rebuild via setState; como ArchbaseCrudListScreen
      // gerencia internamente, basta reabrir caso necessário.
    }
  }
}

class _VisitaCard extends StatelessWidget {
  const _VisitaCard({required this.visita, required this.index});

  final Visita visita;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = switch (visita.status) {
      VisitaStatus.planejada =>
        visita.atrasada ? Colors.orange : Colors.blue,
      VisitaStatus.emAndamento => Colors.amber,
      VisitaStatus.concluida => Colors.green,
      VisitaStatus.cancelada => Colors.grey,
    };
    final icon = switch (visita.status) {
      VisitaStatus.planejada => LucideIcons.calendar,
      VisitaStatus.emAndamento => LucideIcons.clock,
      VisitaStatus.concluida => LucideIcons.circleCheck,
      VisitaStatus.cancelada => LucideIcons.circleSlash,
    };

    return ArchbaseCard(
      key: ValueKey('${TestKeys.visitaCardPrefix}${visita.id}'),
      title: visita.pdv.nome,
      subtitle: '${visita.pdv.cidadeUf} · ${visita.id}',
      leading: Icon(icon, color: color),
      trailing: const Icon(LucideIcons.chevronRight),
      status: ArchbaseCardStatus(color: color, label: visita.status.label),
      body: visita.observacao == null
          ? null
          : Text(
              visita.observacao!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
    );
  }
}
