/// Conversões de naming usadas pelo scaffold. Aceitam input em qualquer
/// estilo (kebab, snake, camel, pascal) e devolvem a forma canônica.
class Casing {
  Casing._();

  /// Quebra `input` em palavras a partir de separadores ou borda de case.
  static List<String> _words(String input) {
    if (input.isEmpty) return const [];
    // Substitui separadores por espaço, depois insere espaço antes de
    // letras maiúsculas no meio de palavras (`fooBar` → `foo Bar`).
    final spaced = input
        .replaceAll(RegExp(r'[\s_\-./]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m[1]} ${m[2]}',
        );
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();
  }

  static String snake(String input) => _words(input).join('_');

  static String kebab(String input) => _words(input).join('-');

  static String pascal(String input) => _words(input).map(_capitalize).join();

  static String camel(String input) {
    final ws = _words(input);
    if (ws.isEmpty) return '';
    return ws.first + ws.skip(1).map(_capitalize).join();
  }

  static String human(String input) => _words(input).map(_capitalize).join(' ');

  static String _capitalize(String w) =>
      w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1);
}
