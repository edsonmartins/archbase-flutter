import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/connectivity/archbase_connectivity_service.dart';
import '../../services/offline/archbase_offline_sync_queue.dart';
import '../../services/offline/archbase_sync_status.dart';
import '../../theme/archbase_theme_extensions.dart';
import '../../utils/formatters/archbase_date_formatter.dart';

/// Banner que mostra o estado da fila offline (offline / sincronizando /
/// pendentes).
///
/// É auto-coletor: se conectado e sem pendências, ocupa zero pixels.
///
/// Aceita tanto a [ArchbaseOfflineSyncQueue] real quanto, para testes,
/// um par de [ValueListenable]s ligados aos mesmos sinais via
/// [ArchbaseSyncStatusBanner.fromListenables].
class ArchbaseSyncStatusBanner extends StatelessWidget {
  const ArchbaseSyncStatusBanner({
    super.key,
    required this.queue,
    required this.connectivity,
    this.dense = false,
    this.onTap,
  })  : _statusListenable = null,
        _onlineListenable = null;

  /// Constrói o banner a partir de listenables avulsos. Útil para testes
  /// e para apps que mantêm o status em outro container (ex.: Riverpod).
  const ArchbaseSyncStatusBanner.fromListenables({
    super.key,
    required ValueListenable<ArchbaseSyncStatus> status,
    required ValueListenable<bool> online,
    this.dense = false,
    this.onTap,
  })  : queue = null,
        connectivity = null,
        _statusListenable = status,
        _onlineListenable = online;

  final ArchbaseOfflineSyncQueue? queue;
  final ArchbaseConnectivityService? connectivity;
  final ValueListenable<ArchbaseSyncStatus>? _statusListenable;
  final ValueListenable<bool>? _onlineListenable;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onlineNotifier = _onlineListenable ?? connectivity!.isConnected;
    final statusNotifier = _statusListenable ?? queue!.status;

    return ValueListenableBuilder<bool>(
      valueListenable: onlineNotifier,
      builder: (context, online, _) {
        return ValueListenableBuilder<ArchbaseSyncStatus>(
          valueListenable: statusNotifier,
          builder: (context, status, __) {
            if (online && !status.hasPending && !status.isSyncing) {
              return const SizedBox.shrink();
            }
            return _Banner(
              online: online,
              status: status,
              dense: dense,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.online,
    required this.status,
    required this.dense,
    required this.onTap,
  });

  final bool online;
  final ArchbaseSyncStatus status;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbaseColors;
    final scheme = !online
        ? _BannerScheme(
            color: colors.warning,
            icon: LucideIcons.wifiOff,
            text: status.hasPending
                ? 'Offline — ${status.pending} alterações aguardando envio'
                : 'Sem conexão',
          )
        : status.isSyncing
            ? _BannerScheme(
                color: colors.info,
                icon: LucideIcons.refreshCw,
                text: 'Sincronizando ${status.pending} alterações…',
              )
            : _BannerScheme(
                color: colors.warning,
                icon: LucideIcons.cloudUpload,
                text: '${status.pending} alterações pendentes',
              );

    return Material(
      color: scheme.color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(scheme.icon, color: scheme.color, size: dense ? 16 : 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  scheme.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (status.lastSyncAt != null && online)
                Text(
                  ArchbaseDateFormatter.relative(status.lastSyncAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.color.withValues(alpha: 0.7),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerScheme {
  _BannerScheme({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;
}
