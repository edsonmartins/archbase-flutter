import 'package:flutter/material.dart';

import '../../widgets/layout/archbase_app_bar.dart';

class ArchbaseDetailSection {
  ArchbaseDetailSection({
    required this.title,
    required this.builder,
    this.icon,
  });

  final String title;
  final WidgetBuilder builder;
  final IconData? icon;
}

/// Tela de detalhes orientada a seções/abas. Aceita header destacado,
/// abas opcionais e ações no AppBar/bottom.
class ArchbaseDetailScreen extends StatelessWidget {
  const ArchbaseDetailScreen({
    super.key,
    required this.title,
    required this.sections,
    this.subtitle,
    this.header,
    this.appBarActions = const [],
    this.bottomActions = const [],
    this.useTabs = false,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final List<ArchbaseDetailSection> sections;
  final List<Widget> appBarActions;
  final List<Widget> bottomActions;
  final bool useTabs;

  @override
  Widget build(BuildContext context) {
    if (useTabs && sections.length > 1) {
      return DefaultTabController(
        length: sections.length,
        child: Scaffold(
          appBar: ArchbaseAppBar(
            title: title,
            subtitle: subtitle,
            actions: appBarActions,
            bottom: TabBar(
              isScrollable: true,
              tabs: sections
                  .map(
                    (s) => Tab(
                      icon: s.icon == null ? null : Icon(s.icon),
                      text: s.title,
                    ),
                  )
                  .toList(),
            ),
          ),
          body: Column(
            children: [
              if (header != null) header!,
              Expanded(
                child: TabBarView(
                  children: sections.map((s) => s.builder(context)).toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottom(context),
        ),
      );
    }
    return Scaffold(
      appBar: ArchbaseAppBar(
        title: title,
        subtitle: subtitle,
        actions: appBarActions,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (header != null) header!,
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (section.icon != null) ...[
                    Icon(section.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            section.builder(context),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottom(context),
    );
  }

  Widget? _buildBottom(BuildContext context) {
    if (bottomActions.isEmpty) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            for (final a in bottomActions) ...[
              Expanded(child: a),
              if (a != bottomActions.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
