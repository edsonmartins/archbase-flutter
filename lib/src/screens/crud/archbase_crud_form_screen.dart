import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/dialogs/archbase_alert_dialog.dart';
import '../../widgets/dialogs/archbase_confirm_dialog.dart';
import '../../widgets/forms/archbase_button.dart';
import '../../widgets/layout/archbase_app_bar.dart';

/// Tela de formulário CRUD genérica.
///
/// O `formBuilder` recebe o `formKey` e devolve o conteúdo do form.
/// O `onSubmit` é chamado após validação — devolve `null` em sucesso ou
/// uma mensagem de erro a exibir.
class ArchbaseCrudFormScreen extends StatefulWidget {
  const ArchbaseCrudFormScreen({
    super.key,
    required this.title,
    required this.formBuilder,
    required this.onSubmit,
    this.subtitle,
    this.submitLabel = 'Salvar',
    this.onDelete,
    this.deleteLabel = 'Excluir',
    this.confirmDiscardOnPop = true,
    this.padding = const EdgeInsets.all(16),
    this.extraActions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget Function(BuildContext context, GlobalKey<FormState> formKey)
      formBuilder;
  final Future<String?> Function() onSubmit;
  final Future<String?> Function()? onDelete;
  final String submitLabel;
  final String deleteLabel;
  final bool confirmDiscardOnPop;
  final EdgeInsets padding;
  final List<Widget> extraActions;

  @override
  State<ArchbaseCrudFormScreen> createState() => _ArchbaseCrudFormScreenState();
}

class _ArchbaseCrudFormScreenState extends State<ArchbaseCrudFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _deleting = false;
  bool _dirty = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final err = await widget.onSubmit();
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      await ArchbaseAlertDialog.show(
        context,
        title: 'Não foi possível salvar',
        message: err,
        severity: ArchbaseAlertSeverity.error,
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await ArchbaseConfirmDialog.show(
      context,
      title: 'Confirmar exclusão',
      message: 'Esta ação não pode ser desfeita.',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    setState(() => _deleting = true);
    final err = await widget.onDelete!();
    if (!mounted) return;
    setState(() => _deleting = false);
    if (err != null) {
      await ArchbaseAlertDialog.show(
        context,
        title: 'Falha ao excluir',
        message: err,
        severity: ArchbaseAlertSeverity.error,
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _onWillPop() async {
    if (!widget.confirmDiscardOnPop || !_dirty) return true;
    return ArchbaseConfirmDialog.show(
      context,
      title: 'Descartar alterações?',
      message: 'Você tem alterações não salvas. Descartar?',
      confirmLabel: 'Descartar',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_dirty || !widget.confirmDiscardOnPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final allow = await _onWillPop();
        if (allow && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: ArchbaseAppBar(
          title: widget.title,
          subtitle: widget.subtitle,
          actions: widget.extraActions,
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: SingleChildScrollView(
            padding: widget.padding,
            child: widget.formBuilder(context, _formKey),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (widget.onDelete != null)
                  Expanded(
                    child: ArchbaseButton(
                      label: widget.deleteLabel,
                      icon: LucideIcons.trash2,
                      variant: ArchbaseButtonVariant.danger,
                      isLoading: _deleting,
                      onPressed:
                          _saving || _deleting ? null : _delete,
                    ),
                  ),
                if (widget.onDelete != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ArchbaseButton(
                    label: widget.submitLabel,
                    icon: LucideIcons.check,
                    isLoading: _saving,
                    onPressed: _saving || _deleting ? null : _submit,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
