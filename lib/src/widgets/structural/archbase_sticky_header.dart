import 'package:flutter/material.dart';

/// Header que gruda no topo do scroll enquanto o conteúdo passa.
///
/// Use dentro de um [CustomScrollView] como `SliverPersistentHeader`,
/// ou direto no body como wrapper de uma seção scrollable.
class ArchbaseStickyHeader extends StatelessWidget {
  const ArchbaseStickyHeader({
    super.key,
    required this.header,
    required this.child,
    this.headerHeight = 56,
  });

  final Widget header;
  final Widget child;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyDelegate(
            child: header,
            height: headerHeight,
          ),
        ),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

/// Header delegate para uso direto em CustomScrollView com múltiplas
/// seções stickies (ex.: lista agrupada).
class ArchbaseStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  ArchbaseStickyHeaderDelegate({
    required this.child,
    this.height = 56,
  });

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: SizedBox(height: height, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _StickyDelegate extends ArchbaseStickyHeaderDelegate {
  _StickyDelegate({required super.child, super.height});
}
