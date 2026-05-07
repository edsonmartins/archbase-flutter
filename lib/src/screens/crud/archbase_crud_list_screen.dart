import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/paginated_response.dart';
import '../../widgets/feedback/archbase_empty_state.dart';
import '../../widgets/feedback/archbase_error_view.dart';
import '../../widgets/feedback/archbase_shimmer.dart';
import '../../widgets/forms/archbase_search_field.dart';
import '../../widgets/layout/archbase_app_bar.dart';

/// Origem dos dados — devolva uma página dado um `page`/`query`.
typedef ArchbaseListLoader<T> = Future<PaginatedResponse<T>> Function({
  required int page,
  required String? query,
  Map<String, dynamic>? filters,
});

/// Tela de listagem CRUD genérica.
///
/// - Pull-to-refresh
/// - Busca com debounce
/// - Paginação infinita (scroll)
/// - Empty / loading / error states
/// - FAB de criar
class ArchbaseCrudListScreen<T> extends StatefulWidget {
  const ArchbaseCrudListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.itemBuilder,
    this.subtitle,
    this.onCreate,
    this.onItemTap,
    this.searchEnabled = true,
    this.searchHint = 'Buscar…',
    this.emptyTitle = 'Nada por aqui',
    this.emptyMessage,
    this.emptyAction,
    this.pageSize = 20,
    this.appBarActions = const [],
    this.headerBuilder,
    this.filtersBuilder,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final String title;
  final String? subtitle;
  final ArchbaseListLoader<T> loader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback? onCreate;
  final void Function(T item)? onItemTap;
  final bool searchEnabled;
  final String searchHint;
  final String emptyTitle;
  final String? emptyMessage;
  final Widget? emptyAction;
  final int pageSize;
  final List<Widget> appBarActions;
  final Widget Function(BuildContext context)? headerBuilder;
  final Widget Function(BuildContext context)? filtersBuilder;
  final EdgeInsets padding;

  @override
  State<ArchbaseCrudListScreen<T>> createState() =>
      _ArchbaseCrudListScreenState<T>();
}

class _ArchbaseCrudListScreenState<T> extends State<ArchbaseCrudListScreen<T>> {
  final _scroll = ScrollController();

  PaginatedResponse<T>? _data;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  String? _query;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore) return;
    final data = _data;
    if (data == null || !data.hasMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      if (reset) {
        _loading = true;
        _data = null;
      }
      _error = null;
    });
    try {
      final response = await widget.loader(page: 0, query: _query);
      if (!mounted) return;
      setState(() {
        _data = response;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final data = _data;
    if (data == null) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.loader(
        page: data.nextPage,
        query: _query,
      );
      if (!mounted) return;
      setState(() {
        _data = data.appendPage(next);
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String value) {
    _query = value.isEmpty ? null : value;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArchbaseAppBar(
        title: widget.title,
        subtitle: widget.subtitle,
        actions: widget.appBarActions,
      ),
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton(
              onPressed: widget.onCreate,
              child: const Icon(LucideIcons.plus),
            ),
      body: Column(
        children: [
          if (widget.searchEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: ArchbaseSearchField(
                onChanged: _onSearch,
                hint: widget.searchHint,
              ),
            ),
          if (widget.filtersBuilder != null) widget.filtersBuilder!(context),
          if (widget.headerBuilder != null) widget.headerBuilder!(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ArchbaseShimmerList();
    if (_error != null) {
      return ArchbaseErrorView(
        message: _error.toString(),
        onRetry: () => _load(reset: true),
      );
    }
    final data = _data;
    if (data == null || data.isEmpty) {
      return ArchbaseEmptyState(
        title: widget.emptyTitle,
        message: widget.emptyMessage,
        actionLabel: widget.emptyAction == null ? null : 'Criar novo',
        onAction: widget.onCreate,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding,
        itemCount: data.content.length + (data.hasMore ? 1 : 0),
        itemBuilder: (context, idx) {
          if (idx >= data.content.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = data.content[idx];
          final widgetItem = widget.itemBuilder(context, item, idx);
          if (widget.onItemTap == null) return widgetItem;
          return InkWell(
            onTap: () => widget.onItemTap!(item),
            child: widgetItem,
          );
        },
      ),
    );
  }
}
