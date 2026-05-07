import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Skeleton/shimmer com cores tema-aware.
class ArchbaseShimmer extends StatelessWidget {
  const ArchbaseShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2C32) : const Color(0xFFE6E8EB),
      highlightColor: isDark ? const Color(0xFF373A41) : const Color(0xFFF7F8FA),
      child: child,
    );
  }
}

/// Atalho para um card-skeleton típico (linha alta + linhas curtas).
class ArchbaseShimmerCard extends StatelessWidget {
  const ArchbaseShimmerCard({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ArchbaseShimmer(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Lista de skeletons.
class ArchbaseShimmerList extends StatelessWidget {
  const ArchbaseShimmerList({super.key, this.count = 6, this.itemHeight = 96});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) => ArchbaseShimmerCard(height: itemHeight),
    );
  }
}
