import 'package:flutter/material.dart';

import '../../models/labeled_enum.dart';

/// `DropdownButtonFormField` opinado da archbase, com helpers para
/// listas de objetos e enums [LabeledEnum].
class ArchbaseDropdown<T> extends StatelessWidget {
  const ArchbaseDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemLabel,
    this.label,
    this.hint,
    this.helper,
    this.required = false,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  final List<T> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String Function(T item) itemLabel;
  final String? label;
  final String? hint;
  final String? helper;
  final bool required;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label != null && required ? '$label *' : label,
        hintText: hint,
        helperText: helper,
        prefixIcon: prefixIcon,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(itemLabel(e), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  /// Construtor especializado para enums com [LabeledEnum].
  static Widget forEnum<E extends LabeledEnum>({
    Key? key,
    required List<E> values,
    required E? value,
    required ValueChanged<E?>? onChanged,
    String? label,
    String? hint,
    bool required = false,
    String? Function(E?)? validator,
    Widget? prefixIcon,
  }) {
    return ArchbaseDropdown<E>(
      key: key,
      items: values,
      value: value,
      onChanged: onChanged,
      itemLabel: (e) => e.label,
      label: label,
      hint: hint,
      required: required,
      validator: validator,
      prefixIcon: prefixIcon,
    );
  }
}
