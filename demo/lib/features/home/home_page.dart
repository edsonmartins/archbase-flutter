import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../keys/test_keys.dart';
import '../auth/login_page.dart';
import '../settings/settings_page.dart';
import '../visitas/visitas_history_page.dart';
import '../visitas/visitas_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.services});

  final AppServices services;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final List<Widget> _pages = [
    VisitasListPage(services: widget.services),
    VisitasHistoryPage(services: widget.services),
    SettingsPage(services: widget.services, onLogout: _handleLogout),
  ];

  Future<void> _handleLogout() async {
    await widget.services.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(services: widget.services)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list, key: ValueKey(TestKeys.tabVisitas)),
            label: 'Visitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LucideIcons.history,
              key: ValueKey(TestKeys.tabHistorico),
            ),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LucideIcons.settings,
              key: ValueKey(TestKeys.tabSettings),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
