import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArchbaseAppBar(title: 'Galeria de widgets'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ArchbaseSectionHeader(
            title: 'Loading',
            icon: LucideIcons.loader,
          ),
          const SizedBox(height: 8),
          const ArchbaseLoading(label: 'Carregando…'),
          const SizedBox(height: 16),
          const ArchbaseSectionHeader(
            title: 'Empty state',
            icon: LucideIcons.inbox,
          ),
          const ArchbaseEmptyState(
            title: 'Sem registros',
            message: 'Você ainda não cadastrou nenhum item.',
          ),
          const ArchbaseSectionHeader(
            title: 'Error',
            icon: LucideIcons.circleAlert,
          ),
          ArchbaseErrorView(
            compact: true,
            message: 'Falha ao carregar dados.',
            onRetry: () {},
          ),
          const SizedBox(height: 16),
          const ArchbaseSectionHeader(
            title: 'Botões',
            icon: LucideIcons.mouse,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ArchbaseButton(label: 'Primário', onPressed: () {}),
              ArchbaseButton(
                label: 'Secundário',
                onPressed: () {},
                variant: ArchbaseButtonVariant.secondary,
              ),
              ArchbaseButton(
                label: 'Ghost',
                onPressed: () {},
                variant: ArchbaseButtonVariant.ghost,
              ),
              ArchbaseButton(
                label: 'Excluir',
                onPressed: () {},
                variant: ArchbaseButtonVariant.danger,
                icon: LucideIcons.trash2,
              ),
              ArchbaseButton(
                label: 'Carregando',
                onPressed: () {},
                isLoading: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ArchbaseSectionHeader(
            title: 'Inputs',
            icon: LucideIcons.text,
          ),
          ArchbaseTextField(
            label: 'Telefone',
            inputFormatters: [ArchbaseMaskFormatter.phoneBr],
            keyboardType: TextInputType.phone,
            validator: ArchbaseValidators.phoneBr,
          ),
          const SizedBox(height: 12),
          const ArchbasePasswordField(),
          const SizedBox(height: 16),
          const ArchbaseSectionHeader(
            title: 'Confirmação por swipe',
            icon: LucideIcons.arrowRight,
          ),
          ArchbaseSwipeToConfirm(
            label: 'Deslize para confirmar',
            onConfirm: () {
              ArchbaseToast.show(
                context,
                message: 'Confirmado!',
                severity: ArchbaseAlertSeverity.success,
              );
            },
          ),
          const SizedBox(height: 16),
          const ArchbaseSectionHeader(
            title: 'Diálogos',
            icon: LucideIcons.messageSquare,
          ),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => ArchbaseConfirmDialog.show(
                  context,
                  title: 'Confirmar?',
                  message: 'Tem certeza?',
                ),
                child: const Text('Confirm dialog'),
              ),
              OutlinedButton(
                onPressed: () => ArchbaseAlertDialog.show(
                  context,
                  title: 'Sucesso',
                  message: 'Operação concluída.',
                  severity: ArchbaseAlertSeverity.success,
                ),
                child: const Text('Alert success'),
              ),
              OutlinedButton(
                onPressed: () => ArchbaseBottomSheet.show<void>(
                  context,
                  title: 'Filtros',
                  child: const Text('Conteúdo do bottom sheet…'),
                ),
                child: const Text('Bottom sheet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
