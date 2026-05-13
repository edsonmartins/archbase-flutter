import 'dart:io';

import 'package:path/path.dart' as p;

import 'casing.dart';

/// Resultado da geração — caminhos absolutos dos arquivos criados.
class ScaffoldResult {
  ScaffoldResult({required this.basePath, required this.files});

  final String basePath;
  final List<String> files;
}

/// Gera o esqueleto de uma feature CRUD no estilo do demo:
///
/// ```
///   features/{name}/
///     models/{name}.dart       — DTO + LabeledEnum de status
///     {name}_repository.dart   — wrapper do ArchbaseApiClient
///     {name}_controller.dart   — ArchbaseController + state
///     {name}_list_page.dart    — ArchbaseCrudListScreen
///     {name}_form_page.dart    — ArchbaseCrudFormScreen
///     {name}_detail_page.dart  — ArchbaseDetailScreen
/// ```
class FeatureScaffold {
  FeatureScaffold({
    required this.name,
    required this.targetRoot,
    this.endpoint,
    this.overwrite = false,
  });

  /// Nome bruto da feature (aceita kebab, snake, camel, pascal).
  final String name;

  /// Diretório raiz do app onde `features/<name>/` será criado. Em geral
  /// `lib/`.
  final String targetRoot;

  /// Path do endpoint REST. Default: `/${snake(name)}s` (lista).
  final String? endpoint;

  /// Se `true`, sobrescreve arquivos existentes; senão, falha se algum
  /// já existir.
  final bool overwrite;

  String get _snake => Casing.snake(name);
  String get _pascal => Casing.pascal(name);
  String get _human => Casing.human(name);
  String get _endpoint => endpoint ?? '/${_snake}s';

  ScaffoldResult run() {
    final base = p.join(targetRoot, 'features', _snake);
    final modelsDir = p.join(base, 'models');

    Directory(modelsDir).createSync(recursive: true);

    final files = <String, String>{
      p.join(modelsDir, '$_snake.dart'): _model(),
      p.join(base, '${_snake}_repository.dart'): _repository(),
      p.join(base, '${_snake}_controller.dart'): _controller(),
      p.join(base, '${_snake}_list_page.dart'): _listPage(),
      p.join(base, '${_snake}_form_page.dart'): _formPage(),
      p.join(base, '${_snake}_detail_page.dart'): _detailPage(),
    };

    if (!overwrite) {
      final existing = files.keys.where((f) => File(f).existsSync()).toList();
      if (existing.isNotEmpty) {
        throw StateError(
          'Arquivos já existem (use --force para sobrescrever):\n'
          '  ${existing.join('\n  ')}',
        );
      }
    }

    for (final entry in files.entries) {
      File(entry.key).writeAsStringSync(entry.value);
    }

    return ScaffoldResult(basePath: base, files: files.keys.toList()..sort());
  }

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  String _model() => '''
import 'package:archbase_flutter/archbase_flutter.dart';

/// Estados possíveis para [$_pascal]. Ajuste conforme o domínio.
enum ${_pascal}Status with LabeledEnum {
  active('ACTIVE', 'Ativo'),
  inactive('INACTIVE', 'Inativo');

  const ${_pascal}Status(this.value, this.label);

  @override
  final String value;
  @override
  final String label;
}

/// $_human — modelo gerado pelo `archbase` CLI.
///
/// Edite para refletir os campos reais do domínio.
class $_pascal implements BaseDto {
  $_pascal({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final ${_pascal}Status status;
  final DateTime? createdAt;

  $_pascal copyWith({
    String? name,
    ${_pascal}Status? status,
    DateTime? createdAt,
  }) {
    return $_pascal(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status.value,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory $_pascal.fromJson(Map<String, dynamic> json) {
    return $_pascal(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      status: LabeledEnums.fromString(
        ${_pascal}Status.values,
        json['status']?.toString(),
      ),
      createdAt: JsonParse.date(json['createdAt']),
    );
  }
}
''';

  String _repository() => '''
import 'package:archbase_flutter/archbase_flutter.dart';

import 'models/$_snake.dart';

/// Camada fina sobre o [ArchbaseApiClient] para `$_human`. Cuida de
/// serializar/deserializar e expor a paginação.
class ${_pascal}Repository {
  ${_pascal}Repository(this._api);

  final ArchbaseApiClient _api;

  Future<PaginatedResponse<$_pascal>> list({
    required int page,
    int size = 20,
    String? query,
  }) async {
    final response = await _api.getPaged<$_pascal>(
      '$_endpoint',
      $_pascal.fromJson,
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.isNotEmpty) 'query': query,
      },
    );
    return response.orThrow();
  }

  Future<$_pascal> get(String id) async {
    final response = await _api.getJson<$_pascal>(
      '$_endpoint/\$id',
      $_pascal.fromJson,
    );
    return response.orThrow();
  }

  Future<$_pascal> create(Map<String, dynamic> payload) async {
    final response = await _api.postJson<$_pascal>(
      '$_endpoint',
      payload,
      $_pascal.fromJson,
    );
    return response.orThrow();
  }

  Future<$_pascal> update(String id, Map<String, dynamic> payload) async {
    final response = await _api.putJson<$_pascal>(
      '$_endpoint/\$id',
      payload,
      $_pascal.fromJson,
    );
    return response.orThrow();
  }

  Future<void> delete(String id) async {
    final response = await _api.delete('$_endpoint/\$id');
    response.orThrow();
  }
}
''';

  String _controller() => '''
import 'package:archbase_flutter/archbase_flutter.dart';

import 'models/$_snake.dart';
import '${_snake}_repository.dart';

/// Estado da feature `$_human`. Mantém a página atual + lista acumulada.
class ${_pascal}State extends ArchbaseControllerState {
  const ${_pascal}State({
    super.isLoading,
    super.error,
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.query,
  });

  final List<$_pascal> items;
  final int page;
  final bool hasMore;
  final String? query;

  @override
  ${_pascal}State copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<$_pascal>? items,
    int? page,
    bool? hasMore,
    String? query,
  }) {
    return ${_pascal}State(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
    );
  }
}

/// Controller da feature `$_human`. Use `guard()` em volta de chamadas
/// async pra ter loading/erro automáticos.
class ${_pascal}Controller extends ArchbaseController<${_pascal}State> {
  ${_pascal}Controller(this._repo) : super(const ${_pascal}State());

  final ${_pascal}Repository _repo;

  Future<void> loadFirstPage({String? query}) async {
    await guard(() async {
      final response = await _repo.list(page: 0, query: query);
      state = state.copyWith(
        items: response.content,
        page: 0,
        hasMore: response.hasMore,
        query: query,
      );
    });
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    await guard(() async {
      final next = state.page + 1;
      final response = await _repo.list(page: next, query: state.query);
      state = state.copyWith(
        items: [...state.items, ...response.content],
        page: next,
        hasMore: response.hasMore,
      );
    });
  }

  Future<bool> save({String? id, required Map<String, dynamic> payload}) async {
    final result = await guard(() async {
      if (id == null) {
        await _repo.create(payload);
      } else {
        await _repo.update(id, payload);
      }
      await loadFirstPage(query: state.query);
      return true;
    });
    return result ?? false;
  }

  Future<bool> remove(String id) async {
    final result = await guard(() async {
      await _repo.delete(id);
      state = state.copyWith(
        items: state.items.where((i) => i.id != id).toList(),
      );
      return true;
    });
    return result ?? false;
  }
}
''';

  String _listPage() => '''
import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'models/$_snake.dart';
import '${_snake}_form_page.dart';
import '${_snake}_repository.dart';

class ${_pascal}ListPage extends StatelessWidget {
  const ${_pascal}ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ${_pascal}Repository(ArchbaseBootstrap.api);

    return ArchbaseCrudListScreen<$_pascal>(
      title: '$_human',
      loader: ({required page, required query, filters}) {
        return repo.list(page: page, query: query);
      },
      onCreate: () => _openForm(context),
      onItemTap: (item) => _openForm(context, existing: item),
      itemBuilder: (context, item, idx) => _${_pascal}Card(item: item),
      emptyTitle: 'Nenhum item',
      emptyMessage: 'Toque no + para criar o primeiro',
      searchHint: 'Buscar…',
    );
  }

  Future<void> _openForm(BuildContext context, {$_pascal? existing}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ${_pascal}FormPage(existing: existing),
      ),
    );
  }
}

class _${_pascal}Card extends StatelessWidget {
  const _${_pascal}Card({required this.item});

  final $_pascal item;

  @override
  Widget build(BuildContext context) {
    final color = item.status == ${_pascal}Status.active
        ? Colors.green
        : Colors.grey;
    return ArchbaseCard(
      title: item.name,
      subtitle: 'ID: \${item.id}',
      leading: const Icon(LucideIcons.box),
      trailing: const Icon(LucideIcons.chevronRight),
      status: ArchbaseCardStatus(color: color, label: item.status.label),
    );
  }
}
''';

  String _formPage() => '''
import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import 'models/$_snake.dart';
import '${_snake}_repository.dart';

class ${_pascal}FormPage extends StatefulWidget {
  const ${_pascal}FormPage({super.key, this.existing});

  final $_pascal? existing;

  @override
  State<${_pascal}FormPage> createState() => _${_pascal}FormPageState();
}

class _${_pascal}FormPageState extends State<${_pascal}FormPage> {
  late final TextEditingController _name;
  late ${_pascal}Status _status;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _status = widget.existing?.status ?? ${_pascal}Status.active;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<String?> _submit() async {
    final repo = ${_pascal}Repository(ArchbaseBootstrap.api);
    final payload = {
      'name': _name.text.trim(),
      'status': _status.value,
    };
    try {
      if (widget.existing == null) {
        await repo.create(payload);
      } else {
        await repo.update(widget.existing!.id, payload);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _delete() async {
    final repo = ${_pascal}Repository(ArchbaseBootstrap.api);
    try {
      await repo.delete(widget.existing!.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArchbaseCrudFormScreen(
      title: widget.existing == null ? 'Novo $_human' : 'Editar $_human',
      onSubmit: _submit,
      onDelete: widget.existing == null ? null : _delete,
      formBuilder: (context, formKey) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ArchbaseTextField(
              controller: _name,
              label: 'Nome',
              required: true,
              validator: ArchbaseValidators.required,
            ),
            const SizedBox(height: 12),
            ArchbaseDropdown.forEnum<${_pascal}Status>(
              label: 'Status',
              values: ${_pascal}Status.values,
              value: _status,
              onChanged: (s) {
                if (s != null) setState(() => _status = s);
              },
            ),
          ],
        );
      },
    );
  }
}
''';

  String _detailPage() => '''
import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'models/$_snake.dart';

class ${_pascal}DetailPage extends StatelessWidget {
  const ${_pascal}DetailPage({super.key, required this.item});

  final $_pascal item;

  @override
  Widget build(BuildContext context) {
    return ArchbaseDetailScreen(
      title: item.name,
      subtitle: 'ID: \${item.id}',
      sections: [
        ArchbaseDetailSection(
          title: 'Resumo',
          icon: LucideIcons.info,
          builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: \${item.name}'),
                const SizedBox(height: 8),
                Text('Status: \${item.status.label}'),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text('Criado em: \${item.createdAt}'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
''';
}
