import 'package:intl/intl.dart';

/// Formatadores de moeda e número em pt-BR.
class ArchbaseCurrencyFormatter {
  ArchbaseCurrencyFormatter._();

  static final NumberFormat _brl =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static final NumberFormat _brlCompact =
      NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _decimal = NumberFormat.decimalPattern('pt_BR');

  static String brl(num value) => _brl.format(value);
  static String brlCompact(num value) => _brlCompact.format(value);
  static String decimal(num value) => _decimal.format(value);

  /// `value` em fração (0..1). Use 0.18 para "18%".
  static String percent(num value, {int fractionDigits = 1}) {
    final formatter = NumberFormat.percentPattern('pt_BR')
      ..maximumFractionDigits = fractionDigits;
    return formatter.format(value);
  }

  static double? parseBrl(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'[^\d,\.\-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}
