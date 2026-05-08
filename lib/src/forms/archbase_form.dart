import 'package:flutter/material.dart';

import 'archbase_form_state.dart';

/// Container de formulário Archbase. Difere do [Form] do Material por
/// expor um [ArchbaseFormController] para acesso programático aos
/// valores e erros, sem precisar de keys nos campos.
class ArchbaseForm extends StatefulWidget {
  const ArchbaseForm({
    super.key,
    required this.child,
    this.controller,
    this.initialValues,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onChanged,
  });

  final Widget child;
  final ArchbaseFormController? controller;
  final Map<String, dynamic>? initialValues;
  final AutovalidateMode autovalidateMode;
  final void Function(Map<String, dynamic> values)? onChanged;

  @override
  State<ArchbaseForm> createState() => ArchbaseFormStateW();
}

class ArchbaseFormStateW extends State<ArchbaseForm> {
  late final ArchbaseFormController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _ownsController = false;

  ArchbaseFormController get controller => _controller;
  GlobalKey<FormState> get formKey => _formKey;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ArchbaseFormController(initialValues: widget.initialValues);
    _ownsController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    widget.onChanged?.call(_controller.values);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Roda os validadores de todos os campos. Retorna `true` se válido.
  bool validate() => _formKey.currentState?.validate() ?? false;

  /// Snapshot atual dos valores.
  Map<String, dynamic> read() => _controller.values;

  /// Reseta os campos visualmente e o controller.
  void reset({Map<String, dynamic>? initialValues}) {
    _formKey.currentState?.reset();
    _controller.reset(initialValues: initialValues);
  }

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormScope(
      controller: _controller,
      child: Form(
        key: _formKey,
        autovalidateMode: widget.autovalidateMode,
        child: widget.child,
      ),
    );
  }
}
