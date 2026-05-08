import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';

class ArchbaseAccordionItem {
  const ArchbaseAccordionItem({
    required this.header,
    required this.content,
    this.icon,
    this.expanded = false,
  });

  final String header;
  final Widget content;
  final IconData? icon;
  final bool expanded;
}

/// Accordion com múltiplas seções que abrem/fecham. Aceita modo
/// `singleOpen` (só uma aberta por vez) ou múltiplas abertas.
class ArchbaseAccordion extends StatefulWidget {
  const ArchbaseAccordion({
    super.key,
    required this.items,
    this.singleOpen = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final List<ArchbaseAccordionItem> items;
  final bool singleOpen;
  final EdgeInsets padding;

  @override
  State<ArchbaseAccordion> createState() => _ArchbaseAccordionState();
}

class _ArchbaseAccordionState extends State<ArchbaseAccordion> {
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.items.map((i) => i.expanded).toList();
  }

  void _toggle(int idx) {
    setState(() {
      if (widget.singleOpen) {
        for (var i = 0; i < _expanded.length; i++) {
          _expanded[i] = i == idx ? !_expanded[i] : false;
        }
      } else {
        _expanded[idx] = !_expanded[idx];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Column(
      children: [
        for (var i = 0; i < widget.items.length; i++)
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _toggle(i),
                  child: Padding(
                    padding: widget.padding,
                    child: Row(
                      children: [
                        if (widget.items[i].icon != null) ...[
                          Icon(widget.items[i].icon),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.items[i].header,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _expanded[i] ? 0.5 : 0,
                          child: const Icon(LucideIcons.chevronDown),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _expanded[i]
                      ? Padding(
                          padding: widget.padding,
                          child: widget.items[i].content,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
