import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'archbase_text_field.dart';

/// Campo de senha com toggle para revelar/ocultar.
class ArchbasePasswordField extends StatefulWidget {
  const ArchbasePasswordField({
    super.key,
    this.label = 'Senha',
    this.controller,
    this.validator,
    this.required = true,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.helper,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool required;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? helper;
  final bool autofocus;

  @override
  State<ArchbasePasswordField> createState() => _ArchbasePasswordFieldState();
}

class _ArchbasePasswordFieldState extends State<ArchbasePasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return ArchbaseTextField(
      label: widget.label,
      controller: widget.controller,
      validator: widget.validator,
      required: widget.required,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      helper: widget.helper,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.visiblePassword,
      maxLines: 1,
      obscureText: _obscure,
      prefixIcon: const Icon(LucideIcons.lock),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
