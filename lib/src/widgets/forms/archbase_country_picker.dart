import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../dialogs/archbase_bottom_sheet.dart';

/// Dados básicos de um país.
class ArchbaseCountry {
  const ArchbaseCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
  });

  /// ISO 3166-1 alpha-2 (BR, US, ...).
  final String code;
  final String name;

  /// Emoji da bandeira (usa codepoint regional indicator).
  final String flag;

  /// Código de discagem internacional com `+` (ex.: `+55`).
  final String dialCode;
}

/// Conjunto curado de países (~30) cobrindo Brasil + maiores parceiros
/// comerciais. Apps que precisem da lista completa devem fornecer
/// `customList`.
class ArchbaseCountries {
  ArchbaseCountries._();

  static const List<ArchbaseCountry> common = [
    ArchbaseCountry(code: 'BR', name: 'Brasil', flag: '🇧🇷', dialCode: '+55'),
    ArchbaseCountry(
        code: 'PT', name: 'Portugal', flag: '🇵🇹', dialCode: '+351'),
    ArchbaseCountry(
        code: 'AR', name: 'Argentina', flag: '🇦🇷', dialCode: '+54'),
    ArchbaseCountry(
        code: 'UY', name: 'Uruguai', flag: '🇺🇾', dialCode: '+598'),
    ArchbaseCountry(
        code: 'PY', name: 'Paraguai', flag: '🇵🇾', dialCode: '+595'),
    ArchbaseCountry(code: 'CL', name: 'Chile', flag: '🇨🇱', dialCode: '+56'),
    ArchbaseCountry(
        code: 'CO', name: 'Colômbia', flag: '🇨🇴', dialCode: '+57'),
    ArchbaseCountry(code: 'PE', name: 'Peru', flag: '🇵🇪', dialCode: '+51'),
    ArchbaseCountry(code: 'MX', name: 'México', flag: '🇲🇽', dialCode: '+52'),
    ArchbaseCountry(
        code: 'US', name: 'Estados Unidos', flag: '🇺🇸', dialCode: '+1'),
    ArchbaseCountry(code: 'CA', name: 'Canadá', flag: '🇨🇦', dialCode: '+1'),
    ArchbaseCountry(
        code: 'GB', name: 'Reino Unido', flag: '🇬🇧', dialCode: '+44'),
    ArchbaseCountry(
        code: 'IE', name: 'Irlanda', flag: '🇮🇪', dialCode: '+353'),
    ArchbaseCountry(code: 'ES', name: 'Espanha', flag: '🇪🇸', dialCode: '+34'),
    ArchbaseCountry(code: 'FR', name: 'França', flag: '🇫🇷', dialCode: '+33'),
    ArchbaseCountry(
        code: 'DE', name: 'Alemanha', flag: '🇩🇪', dialCode: '+49'),
    ArchbaseCountry(code: 'IT', name: 'Itália', flag: '🇮🇹', dialCode: '+39'),
    ArchbaseCountry(code: 'NL', name: 'Holanda', flag: '🇳🇱', dialCode: '+31'),
    ArchbaseCountry(code: 'CH', name: 'Suíça', flag: '🇨🇭', dialCode: '+41'),
    ArchbaseCountry(code: 'JP', name: 'Japão', flag: '🇯🇵', dialCode: '+81'),
    ArchbaseCountry(
        code: 'KR', name: 'Coreia do Sul', flag: '🇰🇷', dialCode: '+82'),
    ArchbaseCountry(code: 'CN', name: 'China', flag: '🇨🇳', dialCode: '+86'),
    ArchbaseCountry(code: 'IN', name: 'Índia', flag: '🇮🇳', dialCode: '+91'),
    ArchbaseCountry(
        code: 'AU', name: 'Austrália', flag: '🇦🇺', dialCode: '+61'),
    ArchbaseCountry(
        code: 'NZ', name: 'Nova Zelândia', flag: '🇳🇿', dialCode: '+64'),
    ArchbaseCountry(
        code: 'AE', name: 'Emirados Árabes', flag: '🇦🇪', dialCode: '+971'),
    ArchbaseCountry(code: 'IL', name: 'Israel', flag: '🇮🇱', dialCode: '+972'),
    ArchbaseCountry(
        code: 'ZA', name: 'África do Sul', flag: '🇿🇦', dialCode: '+27'),
  ];

  static ArchbaseCountry byCode(String code) {
    return common.firstWhere(
      (c) => c.code.toLowerCase() == code.toLowerCase(),
      orElse: () => common.first,
    );
  }
}

/// Picker de país. Abre em bottom sheet com busca.
class ArchbaseCountryPicker extends StatelessWidget {
  const ArchbaseCountryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.countries,
    this.showDialCode = true,
    this.showFlag = true,
  });

  final ArchbaseCountry value;
  final ValueChanged<ArchbaseCountry> onChanged;
  final String? label;
  final List<ArchbaseCountry>? countries;
  final bool showDialCode;
  final bool showFlag;

  Future<void> _open(BuildContext context) async {
    final picked = await ArchbaseBottomSheet.show<ArchbaseCountry>(
      context,
      title: label ?? 'Selecione um país',
      heightFactor: 0.75,
      child: _CountryList(
        countries: countries ?? ArchbaseCountries.common,
        showDialCode: showDialCode,
        showFlag: showFlag,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.chevronDown),
        ),
        child: Row(
          children: [
            if (showFlag) ...[
              Text(value.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(value.name)),
            if (showDialCode)
              Text(
                value.dialCode,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryList extends StatefulWidget {
  const _CountryList({
    required this.countries,
    required this.showDialCode,
    required this.showFlag,
  });

  final List<ArchbaseCountry> countries;
  final bool showDialCode;
  final bool showFlag;

  @override
  State<_CountryList> createState() => _CountryListState();
}

class _CountryListState extends State<_CountryList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.countries.where((c) {
      return q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.dialCode.contains(q);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar país…',
            prefixIcon: Icon(LucideIcons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final c = filtered[idx];
              return ListTile(
                leading: widget.showFlag
                    ? Text(c.flag, style: const TextStyle(fontSize: 26))
                    : null,
                title: Text(c.name),
                trailing: widget.showDialCode
                    ? Text(c.dialCode,
                        style: TextStyle(color: Theme.of(context).hintColor))
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              );
            },
          ),
        ),
      ],
    );
  }
}
