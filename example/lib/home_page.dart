import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'crud_demo_page.dart';
import 'fake_auth_service.dart';
import 'gallery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.themeController, required this.auth});

  final ArchbaseThemeController themeController;
  final FakeAuthService auth;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const CrudDemoPage(),
      const GalleryPage(),
      ArchbaseSettingsScreen(
        themeController: widget.themeController,
        appName: 'Archbase Demo',
        appVersion: '0.1.0',
        onLogout: () => widget.auth.logout(),
      ),
    ];

    return ArchbaseScaffold(
      connectivity: ArchbaseBootstrap.connectivity,
      syncQueue: ArchbaseBootstrap.syncQueue,
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'CRUD',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutGrid),
            label: 'Galeria',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
