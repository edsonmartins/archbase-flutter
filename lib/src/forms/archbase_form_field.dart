import 'package:flutter/widgets.dart';

import 'archbase_form_state.dart';

/// Mixin para qualquer campo do formulário declarar seu nome e
/// reportar valores ao controller automaticamente.
///
/// Use `ArchbaseFormField` quando estiver criando novos campos. Para
/// campos prontos da lib (cpf, cnpj, etc.), apenas passe `name:`.
mixin ArchbaseFormFieldMixin<T> {
  String get name;
  ArchbaseFormController? formController(BuildContext context) =>
      ArchbaseFormScope.maybeOf(context);

  void registerValue(BuildContext context, T value) {
    formController(context)?.setValue(name, value);
  }

  T? readInitial(BuildContext context) {
    final ctrl = formController(context);
    return ctrl?.read<T>(name);
  }
}
