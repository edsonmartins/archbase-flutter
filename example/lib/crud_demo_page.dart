import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Cliente {
  _Cliente({required this.id, required this.nome, required this.cidade});
  final String id;
  final String nome;
  final String cidade;
}

final _fakeData = List.generate(
  73,
  (i) => _Cliente(
    id: 'C-${i.toString().padLeft(4, '0')}',
    nome: 'Cliente ${i + 1}',
    cidade: ['São Paulo', 'Rio', 'Curitiba', 'BH', 'POA'][i % 5],
  ),
);

class CrudDemoPage extends StatelessWidget {
  const CrudDemoPage({super.key});

  Future<PaginatedResponse<_Cliente>> _load({
    required int page,
    required String? query,
    Map<String, dynamic>? filters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final all = query == null
        ? _fakeData
        : _fakeData
            .where((c) => c.nome.toLowerCase().contains(query.toLowerCase()))
            .toList();
    const pageSize = 15;
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, all.length);
    return PaginatedResponse(
      content: all.sublist(start.clamp(0, all.length), end),
      totalElements: all.length,
      totalPages: (all.length / pageSize).ceil(),
      currentPage: page,
      pageSize: pageSize,
      first: page == 0,
      last: end >= all.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArchbaseCrudListScreen<_Cliente>(
      title: 'Clientes',
      subtitle: 'Demo CRUD genérico',
      loader: _load,
      onCreate: () => _openForm(context),
      onItemTap: (c) => _openDetails(context, c),
      itemBuilder: (context, c, _) => ArchbaseCard(
        leading: const Icon(LucideIcons.user),
        title: c.nome,
        subtitle: c.cidade,
        trailing: const Icon(LucideIcons.chevronRight),
        status: ArchbaseCardStatus(
          color: c.cidade == 'São Paulo' ? Colors.green : Colors.blue,
          label: c.id,
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, _Cliente c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArchbaseDetailScreen(
          title: c.nome,
          subtitle: c.id,
          appBarActions: [
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              onPressed: () {},
            ),
          ],
          sections: [
            ArchbaseDetailSection(
              title: 'Identificação',
              icon: LucideIcons.idCard,
              builder: (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Cidade'),
                      subtitle: Text(c.cidade),
                      leading: const Icon(LucideIcons.mapPin),
                    ),
                  ],
                ),
              ),
            ),
            ArchbaseDetailSection(
              title: 'Histórico',
              icon: LucideIcons.history,
              builder: (_) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sem histórico ainda.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArchbaseCrudFormScreen(
          title: 'Novo cliente',
          formBuilder: (context, _) => Column(
            children: [
              ArchbaseTextField(
                label: 'Nome',
                required: true,
                controller: nomeCtrl,
                validator: ArchbaseValidators.compose([
                  ArchbaseValidators.required,
                  (v) => ArchbaseValidators.minLength(v, 3),
                ]),
              ),
              const SizedBox(height: 12),
              ArchbaseTextField(
                label: 'E-mail',
                required: true,
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: ArchbaseValidators.email,
              ),
              const SizedBox(height: 12),
              ArchbaseTextField(
                label: 'CPF',
                required: true,
                controller: cpfCtrl,
                inputFormatters: [ArchbaseMaskFormatter.cpf],
                validator: ArchbaseValidators.cpf,
              ),
            ],
          ),
          onSubmit: () async {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            return null;
          },
        ),
      ),
    );
  }
}
