import 'package:flutter/material.dart';

/// Posição do badge sobre o widget pai.
enum ArchbaseBadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  center,
}

/// Badge avançado posicional sobre um child (ex.: ícone de notificação
/// com contador).
class ArchbaseBadgeAdv extends StatelessWidget {
  const ArchbaseBadgeAdv({
    super.key,
    required this.child,
    this.label,
    this.dot = false,
    this.color = Colors.red,
    this.foregroundColor = Colors.white,
    this.position = ArchbaseBadgePosition.topRight,
    this.size = 18,
    this.offset = const Offset(2, -2),
    this.show = true,
  });

  final Widget child;
  final String? label;
  final bool dot;
  final Color color;
  final Color foregroundColor;
  final ArchbaseBadgePosition position;
  final double size;
  final Offset offset;
  final bool show;

  Alignment get _alignment {
    switch (position) {
      case ArchbaseBadgePosition.topRight:
        return Alignment.topRight;
      case ArchbaseBadgePosition.topLeft:
        return Alignment.topLeft;
      case ArchbaseBadgePosition.bottomRight:
        return Alignment.bottomRight;
      case ArchbaseBadgePosition.bottomLeft:
        return Alignment.bottomLeft;
      case ArchbaseBadgePosition.center:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            top: position == ArchbaseBadgePosition.topLeft ||
                    position == ArchbaseBadgePosition.topRight
                ? offset.dy
                : null,
            bottom: position == ArchbaseBadgePosition.bottomLeft ||
                    position == ArchbaseBadgePosition.bottomRight
                ? -offset.dy
                : null,
            left: position == ArchbaseBadgePosition.topLeft ||
                    position == ArchbaseBadgePosition.bottomLeft
                ? -offset.dx
                : null,
            right: position == ArchbaseBadgePosition.topRight ||
                    position == ArchbaseBadgePosition.bottomRight
                ? offset.dx
                : null,
            child: Align(
              alignment: _alignment,
              child: dot
                  ? Container(
                      width: size * 0.5,
                      height: size * 0.5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    )
                  : Container(
                      constraints: BoxConstraints(
                        minWidth: size,
                        minHeight: size,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(size),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: size * 0.55,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
