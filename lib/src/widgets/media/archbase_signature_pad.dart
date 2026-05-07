import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signature/signature.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Pad de assinatura digital + botões de limpar e confirmar.
class ArchbaseSignaturePad extends StatefulWidget {
  const ArchbaseSignaturePad({
    super.key,
    this.height = 220,
    this.penStrokeWidth = 3,
    this.penColor,
    this.exportFormat = ExportFormat.png,
    this.onConfirm,
    this.confirmLabel = 'Confirmar assinatura',
    this.clearLabel = 'Limpar',
    this.placeholder = 'Assine no espaço acima',
  });

  final double height;
  final double penStrokeWidth;
  final Color? penColor;
  final ExportFormat exportFormat;
  final ValueChanged<Uint8List>? onConfirm;
  final String confirmLabel;
  final String clearLabel;
  final String placeholder;

  @override
  State<ArchbaseSignaturePad> createState() => _ArchbaseSignaturePadState();
}

enum ExportFormat { png, svg }

class _ArchbaseSignaturePadState extends State<ArchbaseSignaturePad> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor ?? Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_controller.isEmpty) return;
    final bytes = widget.exportFormat == ExportFormat.png
        ? await _controller.toPngBytes()
        : Uint8List.fromList(_controller.toRawSVG()?.codeUnits ?? const []);
    if (bytes != null) widget.onConfirm?.call(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Column(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Signature(
                    controller: _controller, backgroundColor: Colors.white),
                if (_controller.isEmpty)
                  Center(
                    child: Text(
                      widget.placeholder,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _controller.clear()),
              icon: const Icon(LucideIcons.eraser),
              label: Text(widget.clearLabel),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _confirm,
              icon: const Icon(LucideIcons.check),
              label: Text(widget.confirmLabel),
            ),
          ],
        ),
      ],
    );
  }
}
