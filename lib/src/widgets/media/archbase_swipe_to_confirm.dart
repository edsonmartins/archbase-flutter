import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';

/// "Slide to confirm" para confirmar ações sensíveis (entrega, finalizar
/// viagem, etc.) sem risco de toque acidental.
class ArchbaseSwipeToConfirm extends StatefulWidget {
  const ArchbaseSwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.icon = LucideIcons.arrowRight,
    this.height = 56,
    this.color,
    this.confirmedLabel = 'Confirmado!',
  });

  final String label;
  final VoidCallback onConfirm;
  final IconData icon;
  final double height;
  final Color? color;
  final String confirmedLabel;

  @override
  State<ArchbaseSwipeToConfirm> createState() => _ArchbaseSwipeToConfirmState();
}

class _ArchbaseSwipeToConfirmState extends State<ArchbaseSwipeToConfirm> {
  double _drag = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.archbaseColors.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxDrag = width - widget.height;
        return Stack(
          children: [
            Container(
              width: width,
              height: widget.height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              alignment: Alignment.center,
              child: Text(
                _confirmed ? widget.confirmedLabel : widget.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Positioned(
              left: _drag,
              child: GestureDetector(
                onHorizontalDragUpdate: _confirmed
                    ? null
                    : (details) {
                        setState(() {
                          _drag =
                              (_drag + details.delta.dx).clamp(0.0, maxDrag);
                        });
                      },
                onHorizontalDragEnd: _confirmed
                    ? null
                    : (_) {
                        if (_drag >= maxDrag * 0.85) {
                          setState(() {
                            _drag = maxDrag;
                            _confirmed = true;
                          });
                          widget.onConfirm();
                        } else {
                          setState(() => _drag = 0);
                        }
                      },
                child: Container(
                  width: widget.height,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _confirmed ? LucideIcons.check : widget.icon,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Permite reset externo (ex.: erro no servidor → volta para inicial).
  // ignore: unused_element
  void reset() {
    setState(() {
      _drag = 0;
      _confirmed = false;
    });
  }
}
