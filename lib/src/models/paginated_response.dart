/// Resposta paginada padronizada (compatível com Spring Data Pageable).
class PaginatedResponse<T> {
  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.first = false,
    this.last = false,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool first;
  final bool last;

  bool get hasMore => !last && currentPage + 1 < totalPages;
  int get nextPage => currentPage + 1;
  bool get isEmpty => content.isEmpty;
  int get loadedCount => content.length;

  /// Constrói a partir de um JSON no formato Spring Data
  /// (`content`, `totalElements`, `totalPages`, `number`, `size`,
  /// `first`, `last`).
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromItem,
  ) {
    final list = (json['content'] as List?) ?? const [];
    return PaginatedResponse<T>(
      content: list
          .whereType<Map>()
          .map((e) => fromItem(e.cast<String, dynamic>()))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['number'] as num?)?.toInt() ??
          (json['page'] as num?)?.toInt() ??
          0,
      pageSize: (json['size'] as num?)?.toInt() ?? list.length,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? (list.isEmpty),
    );
  }

  PaginatedResponse<T> appendPage(PaginatedResponse<T> next) {
    return PaginatedResponse<T>(
      content: [...content, ...next.content],
      totalElements: next.totalElements,
      totalPages: next.totalPages,
      currentPage: next.currentPage,
      pageSize: next.pageSize,
      first: first,
      last: next.last,
    );
  }

  PaginatedResponse<R> mapItems<R>(R Function(T item) mapper) {
    return PaginatedResponse<R>(
      content: content.map(mapper).toList(),
      totalElements: totalElements,
      totalPages: totalPages,
      currentPage: currentPage,
      pageSize: pageSize,
      first: first,
      last: last,
    );
  }

  static PaginatedResponse<T> empty<T>() => PaginatedResponse<T>(
        content: const [],
        totalElements: 0,
        totalPages: 0,
        currentPage: 0,
        pageSize: 0,
        first: true,
        last: true,
      );
}
