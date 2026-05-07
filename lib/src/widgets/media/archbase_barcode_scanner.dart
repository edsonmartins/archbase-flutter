import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Tela de scanner com overlay padrão. Abra com `Navigator.push` e
/// resolva o resultado via `Navigator.pop` (`Future<String?>`).
class ArchbaseBarcodeScanner extends StatefulWidget {
  const ArchbaseBarcodeScanner({
    super.key,
    this.title = 'Escanear código',
    this.formats,
    this.autoClose = true,
    this.helperText = 'Aponte a câmera para o código',
  });

  final String title;
  final List<BarcodeFormat>? formats;
  final bool autoClose;
  final String helperText;

  static Future<String?> open(
    BuildContext context, {
    String title = 'Escanear código',
    List<BarcodeFormat>? formats,
    bool autoClose = true,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ArchbaseBarcodeScanner(
          title: title,
          formats: formats,
          autoClose: autoClose,
        ),
      ),
    );
  }

  @override
  State<ArchbaseBarcodeScanner> createState() => _ArchbaseBarcodeScannerState();
}

class _ArchbaseBarcodeScannerState extends State<ArchbaseBarcodeScanner> {
  late MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: widget.formats ?? const [],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !widget.autoClose) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (_, state, __) {
                final on = state.torchState == TorchState.on;
                return Icon(on ? LucideIcons.zapOff : LucideIcons.zap);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.switchCamera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.helperText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
