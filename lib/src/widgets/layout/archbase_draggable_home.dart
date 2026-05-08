import 'package:flutter/material.dart';

/// Scaffold com header "draggable" — colapsa quando o usuário scrolla
/// para cima e expande quando volta para o topo. Útil para telas tipo
/// Trello, Notion, Apple Music etc.
///
/// Versão refeita do AnterosDraggableHome sem RxDart — usa apenas
/// `NotificationListener<ScrollNotification>` + `AnimatedContainer`.
class ArchbaseDraggableHome extends StatefulWidget {
  const ArchbaseDraggableHome({
    super.key,
    required this.title,
    required this.headerWidget,
    required this.body,
    this.expandedHeight = 280,
    this.collapsedHeight = kToolbarHeight + 16,
    this.curvedBodyRadius = 24,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.appBarColor,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.alwaysShowLeadingAndAction = false,
    this.alwaysShowTitle = false,
  });

  final String title;
  final Widget headerWidget;
  final List<Widget> body;
  final double expandedHeight;
  final double collapsedHeight;
  final double curvedBodyRadius;
  final Color? backgroundColor;
  final Color? headerBackgroundColor;
  final Color? appBarColor;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final bool alwaysShowLeadingAndAction;
  final bool alwaysShowTitle;

  @override
  State<ArchbaseDraggableHome> createState() => _ArchbaseDraggableHomeState();
}

class _ArchbaseDraggableHomeState extends State<ArchbaseDraggableHome> {
  bool _collapsed = false;

  bool _onScrollNotification(ScrollNotification notification) {
    final offset = notification.metrics.pixels;
    final shouldCollapse =
        offset > widget.expandedHeight - widget.collapsedHeight;
    if (shouldCollapse != _collapsed) {
      setState(() => _collapsed = shouldCollapse);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showTitle = widget.alwaysShowTitle || _collapsed;
    final showActions = widget.alwaysShowLeadingAndAction || _collapsed;

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? theme.scaffoldBackgroundColor,
      floatingActionButton: widget.floatingActionButton,
      bottomSheet: widget.bottomSheet,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: widget.expandedHeight,
              collapsedHeight: widget.collapsedHeight,
              backgroundColor: _collapsed
                  ? (widget.appBarColor ?? theme.scaffoldBackgroundColor)
                  : (widget.headerBackgroundColor ?? theme.colorScheme.primary),
              leading: showActions ? widget.leading : null,
              actions: showActions ? widget.actions : null,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showTitle ? 1 : 0,
                child: Text(widget.title),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: widget.headerWidget,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      widget.backgroundColor ?? theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.curvedBodyRadius),
                    topRight: Radius.circular(widget.curvedBodyRadius),
                  ),
                ),
                transform:
                    Matrix4.translationValues(0, -widget.curvedBodyRadius, 0),
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
