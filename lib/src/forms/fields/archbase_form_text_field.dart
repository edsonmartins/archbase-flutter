import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../archbase_form_field.dart';
import '../archbase_form_state.dart';

/// TextFormField integrado ao [ArchbaseForm]. Reporta valor ao
/// [ArchbaseFormController] automaticamente via [name].
class ArchbaseFormTextField extends StatefulWidget
    with ArchbaseFormFieldMixin<String> {
  const ArchbaseFormTextField({
    super.key,
    required this.name,
    this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  final String name;

  final String? label;
  final String? hint;
  final String? helper;
  final bool required;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final TextCapitalization textCapitalization;

  @override
  State<ArchbaseFormTextField> createState() => _ArchbaseFormTextFieldState();
}

class _ArchbaseFormTextFieldState extends State<ArchbaseFormTextField> {
  late TextEditingController _controller;
  late ArchbaseFormController? _form;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _form = ArchbaseFormScope.maybeOf(context);
    final initial = _form?.read<String>(widget.name);
    if (initial != null && _controller.text.isEmpty) {
      _controller.text = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _form?.setValue(widget.name, value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization,
      onChanged: _onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label != null && widget.required
            ? '${widget.label} *'
            : widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}
