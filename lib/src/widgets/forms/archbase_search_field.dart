import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/debouncer.dart';

/// Campo de busca padrão (com debounce embutido).
class ArchbaseSearchField extends StatefulWidget {
  const ArchbaseSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.hint = 'Buscar…',
    this.debounce = const Duration(milliseconds: 300),
    this.autofocus = false,
    this.trailing,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String hint;
  final Duration debounce;
  final bool autofocus;
  final Widget? trailing;

  @override
  State<ArchbaseSearchField> createState() => _ArchbaseSearchFieldState();
}

class _ArchbaseSearchFieldState extends State<ArchbaseSearchField> {
  late final TextEditingController _controller;
  late final Debouncer _debouncer;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _debouncer = Debouncer(delay: widget.debounce);
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final text = _controller.text;
    final has = text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
    _debouncer.run(() => widget.onChanged(text));
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(LucideIcons.search),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => _controller.clear(),
              )
            : widget.trailing,
      ),
    );
  }
}
