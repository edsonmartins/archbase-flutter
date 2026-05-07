import 'package:intl/intl.dart';

/// Formatadores de data em pt-BR.
class ArchbaseDateFormatter {
  ArchbaseDateFormatter._();

  static final DateFormat _dateBr = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateTimeBr =
      DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  static final DateFormat _timeBr = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _weekday = DateFormat.EEEE('pt_BR');
  static final DateFormat _monthYear = DateFormat("MMMM 'de' yyyy", 'pt_BR');

  static String date(DateTime value) => _dateBr.format(value);
  static String dateTime(DateTime value) => _dateTimeBr.format(value);
  static String time(DateTime value) => _timeBr.format(value);
  static String weekday(DateTime value) => _weekday.format(value);
  static String monthYear(DateTime value) => _monthYear.format(value);

  /// Versão amigável: "Hoje", "Ontem", "Há 3 dias" ou data completa.
  static String relative(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final target = DateTime(value.year, value.month, value.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Hoje, ${time(value)}';
    if (diffDays == 1) return 'Ontem, ${time(value)}';
    if (diffDays > 1 && diffDays < 7) return 'Há $diffDays dias';
    if (diffDays == -1) return 'Amanhã, ${time(value)}';
    if (diffDays < 0 && diffDays > -7) return 'Em ${diffDays.abs()} dias';
    return date(value);
  }

  /// `mm:ss` (ou `H:mm:ss` se passar de uma hora).
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}
