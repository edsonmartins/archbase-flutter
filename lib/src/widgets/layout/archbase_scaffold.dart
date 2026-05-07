import 'package:flutter/material.dart';

import '../../services/connectivity/archbase_connectivity_service.dart';
import '../../services/offline/archbase_offline_sync_queue.dart';
import '../feedback/archbase_sync_status_banner.dart';

/// Scaffold padrão da archbase. Diferencia-se do `Scaffold` do Material por:
/// - Banner automático de sync/offline no topo (se serviços passados)
/// - Pull-to-refresh opcional via [onRefresh]
class ArchbaseScaffold extends StatelessWidget {
  const ArchbaseScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.syncQueue,
    this.connectivity,
    this.onRefresh,
    this.bottomSheet,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final ArchbaseOfflineSyncQueue? syncQueue;
  final ArchbaseConnectivityService? connectivity;
  final Future<void> Function()? onRefresh;
  final Widget? bottomSheet;

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    final showBanner = syncQueue != null && connectivity != null;

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      body: showBanner
          ? Column(
              children: [
                ArchbaseSyncStatusBanner(
                  queue: syncQueue!,
                  connectivity: connectivity!,
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
