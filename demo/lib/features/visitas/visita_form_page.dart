import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

import '../../bootstrap/app_bootstrap.dart';
import '../../keys/test_keys.dart';
import '../../mock/mock_database.dart';
import 'models/pdv.dart';
import 'models/visita.dart';
import 'visitas_repository.dart';

/// Form de criar / editar visita.
class VisitaFormPage extends StatefulWidget {
  const VisitaFormPage({super.key, required this.services, this.existing});

  final AppServices services;
  final Visita? existing;

  @override
  State<VisitaFormPage> createState() => _VisitaFormPageState();
}

class _VisitaFormPageState extends State<VisitaFormPage> {
  late VisitaStatus _status;
  late DateTime _dataAgendada;
  Pdv? _pdv;
  late TextEditingController _observacaoCtrl;
  late VisitasRepository _repo;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _repo = VisitasRepository(ArchbaseBootstrap.api);
    final v = widget.existing;
    _pdv = v?.pdv ?? MockDatabase.instance.pdvs.values.first;
    _status = v?.status ?? VisitaStatus.planejada;
    _dataAgendada = v?.dataAgendada ?? DateTime.now();
    _observacaoCtrl = TextEditingController(text: v?.observacao ?? '');
  }

  @override
  void dispose() {
    _observacaoCtrl.dispose();
    super.dispose();
  }

  Future<String?> _submit() async {
    final payload = <String, dynamic>{
      'pdvId': _pdv!.id,
      'status': _status.value,
      'dataAgendada': _dataAgendada.toIso8601String(),
      'observacao': _observacaoCtrl.text.trim(),
    };
    try {
      if (_isEditing) {
        await _repo.update(widget.existing!.id, payload);
      } else {
        // Em offline, enfileiramos para envio futuro.
        if (!ArchbaseBootstrap.connectivity.isConnected.value) {
          await ArchbaseBootstrap.syncQueue.enqueue(
            method: SyncMethod.post,
            path: '/visitas',
            payload: payload,
            tag: 'visita',
          );
        } else {
          await _repo.create(payload);
        }
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _delete() async {
    try {
      await _repo.delete(widget.existing!.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdvs = MockDatabase.instance.pdvs.values.toList();
    return ArchbaseCrudFormScreen(
      title: _isEditing ? 'Editar visita' : 'Nova visita',
      subtitle: _isEditing ? widget.existing!.id : null,
      onSubmit: _submit,
      onDelete: _isEditing ? _delete : null,
      formBuilder: (context, _) => Column(
        children: [
          ArchbaseDropdown<Pdv>(
            key: const ValueKey(TestKeys.formPdv),
            label: 'PDV',
            required: true,
            items: pdvs,
            value: _pdv,
            onChanged: (v) => setState(() => _pdv = v),
            itemLabel: (p) => '${p.nome} — ${p.cidadeUf}',
          ),
          const SizedBox(height: 12),
          ArchbaseDropdown.forEnum<VisitaStatus>(
            key: const ValueKey(TestKeys.formStatus),
            label: 'Status',
            required: true,
            values: VisitaStatus.values,
            value: _status,
            onChanged: (s) => setState(() => _status = s ?? _status),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Data agendada'),
            subtitle: Text(ArchbaseDateFormatter.dateTime(_dataAgendada)),
            trailing: const Icon(Icons.edit),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          ArchbaseTextField(
            key: const ValueKey(TestKeys.formObservacao),
            label: 'Observação',
            controller: _observacaoCtrl,
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataAgendada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataAgendada),
    );
    if (time == null) return;
    setState(() {
      _dataAgendada = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}
