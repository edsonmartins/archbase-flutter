import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/formatters/archbase_phone_formatter.dart';
import '../../utils/validators/archbase_validators.dart';
import 'archbase_form_text_field.dart';

/// Campo CPF — máscara + validação inclusas.
class ArchbaseFormCpfField extends StatelessWidget {
  const ArchbaseFormCpfField({
    super.key,
    required this.name,
    this.label = 'CPF',
    this.required = true,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.number,
      inputFormatters: [ArchbaseMaskFormatter.cpf],
      validator: required
          ? ArchbaseValidators.compose([
              ArchbaseValidators.required,
              ArchbaseValidators.cpf,
            ])
          : (v) => ArchbaseValidators.cpf(v, allowEmpty: true),
    );
  }
}

/// Campo CNPJ — máscara + validação.
class ArchbaseFormCnpjField extends StatelessWidget {
  const ArchbaseFormCnpjField({
    super.key,
    required this.name,
    this.label = 'CNPJ',
    this.required = true,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.number,
      inputFormatters: [ArchbaseMaskFormatter.cnpj],
      validator: required
          ? ArchbaseValidators.compose([
              ArchbaseValidators.required,
              ArchbaseValidators.cnpj,
            ])
          : (v) => ArchbaseValidators.cnpj(v, allowEmpty: true),
    );
  }
}

/// Campo CNH com 11 dígitos.
class ArchbaseFormCnhField extends StatelessWidget {
  const ArchbaseFormCnhField({
    super.key,
    required this.name,
    this.label = 'CNH',
    this.required = true,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      validator: required
          ? ArchbaseValidators.compose([
              ArchbaseValidators.required,
              ArchbaseValidators.cnh,
            ])
          : (v) => ArchbaseValidators.cnh(v, allowEmpty: true),
    );
  }
}

/// Campo de placa (padrão antigo + Mercosul).
class ArchbaseFormPlateField extends StatelessWidget {
  const ArchbaseFormPlateField({
    super.key,
    required this.name,
    this.label = 'Placa',
    this.required = true,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [ArchbasePlateFormatter()],
      validator: required
          ? ArchbaseValidators.compose([
              ArchbaseValidators.required,
              ArchbaseValidators.plateBr,
            ])
          : (v) => ArchbaseValidators.plateBr(v, allowEmpty: true),
    );
  }
}

/// Campo de telefone BR (celular ou fixo).
class ArchbaseFormPhoneBrField extends StatelessWidget {
  const ArchbaseFormPhoneBrField({
    super.key,
    required this.name,
    this.label = 'Telefone',
    this.required = false,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.phone,
      inputFormatters: [ArchbaseMaskFormatter.phoneBr],
      validator: (v) => ArchbaseValidators.phoneBr(v, allowEmpty: !required),
    );
  }
}

/// Campo de e-mail.
class ArchbaseFormEmailField extends StatelessWidget {
  const ArchbaseFormEmailField({
    super.key,
    required this.name,
    this.label = 'E-mail',
    this.required = true,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.emailAddress,
      validator: required
          ? ArchbaseValidators.compose([
              ArchbaseValidators.required,
              ArchbaseValidators.email,
            ])
          : (v) => ArchbaseValidators.email(v, allowEmpty: true),
    );
  }
}

/// Campo de CEP.
class ArchbaseFormCepField extends StatelessWidget {
  const ArchbaseFormCepField({
    super.key,
    required this.name,
    this.label = 'CEP',
    this.required = false,
  });

  final String name;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.number,
      inputFormatters: [ArchbaseMaskFormatter.cep],
    );
  }
}

/// Campo de data de nascimento com validação de idade mínima.
class ArchbaseFormBirthDateField extends StatelessWidget {
  const ArchbaseFormBirthDateField({
    super.key,
    required this.name,
    this.label = 'Data de nascimento',
    this.required = true,
    this.minAge,
  });

  final String name;
  final String label;
  final bool required;

  /// Se informado, valida que o usuário tem pelo menos esta idade.
  final int? minAge;

  @override
  Widget build(BuildContext context) {
    final validators = <FormFieldValidator<String>>[
      if (required) ArchbaseValidators.required,
      if (minAge != null)
        ArchbaseValidators.ageMin(
          minAge!,
          message: 'Idade mínima: $minAge anos',
        ),
    ];

    return ArchbaseFormTextField(
      name: name,
      label: label,
      required: required,
      keyboardType: TextInputType.datetime,
      inputFormatters: [ArchbaseMaskFormatter.dateBr],
      validator:
          validators.isEmpty ? null : ArchbaseValidators.compose(validators),
    );
  }
}
