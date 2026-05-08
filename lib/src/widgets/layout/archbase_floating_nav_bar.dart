import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

class ArchbaseFloatingNavBarItem {
  const ArchbaseFloatingNavBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// Bottom navigation bar flutuante (não cola na borda).
///
/// Diferenças vs `BottomNavigationBar`:
/// - Card flutuante com sombra, margem e borderRadius
/// - Item ativo cresce, mostra label inline e tem fundo destacado
/// - Animações suaves
class ArchbaseFloatingNavBar extends StatelessWidget {
  const ArchbaseFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.height = 64,
    this.background,
  });

  final List<ArchbaseFloatingNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final EdgeInsets margin;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Padding(
      padding: margin,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(height / 2),
        color: background ?? colors.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ArchbaseFloatingNavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    final color = selected ? colors.archbase.primary : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.archbase.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 20),
            if (selected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
