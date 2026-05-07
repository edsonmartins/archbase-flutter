import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `TextFormField` opinado da archbase.
///
/// Atalhos para máscaras, validadores, ícones e teclado.
class ArchbaseTextField extends StatelessWidget {
  const ArchbaseTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.autofocus = false,
    this.focusNode,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
  });

  final String? label;
  final String? hint;
  final String? helper;
  final TextEditingController? controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool required;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label != null && required ? '$label *' : label,
        hintText: hint,
        helperText: helper,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
