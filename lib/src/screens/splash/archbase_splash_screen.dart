import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Splash screen padrão. Roda uma tarefa de bootstrap e navega
/// conforme o resultado.
class ArchbaseSplashScreen extends StatefulWidget {
  const ArchbaseSplashScreen({
    super.key,
    required this.bootstrap,
    required this.onReady,
    this.logo,
    this.appName,
    this.tagline,
    this.versionLabel,
    this.minimumDisplay = const Duration(milliseconds: 600),
    this.onError,
  });

  /// Tarefa principal de inicialização — devolve um payload que será
  /// passado para [onReady].
  final Future<Object?> Function() bootstrap;

  /// Callback de navegação após o bootstrap terminar com sucesso.
  final void Function(BuildContext context, Object? payload) onReady;

  /// Callback opcional para falhas no bootstrap.
  final void Function(BuildContext context, Object error)? onError;

  final Widget? logo;
  final String? appName;
  final String? tagline;
  final String? versionLabel;
  final Duration minimumDisplay;

  @override
  State<ArchbaseSplashScreen> createState() => _ArchbaseSplashScreenState();
}

class _ArchbaseSplashScreenState extends State<ArchbaseSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final stopwatch = Stopwatch()..start();
    Object? result;
    Object? error;
    try {
      result = await widget.bootstrap();
    } catch (e) {
      error = e;
    }
    final elapsed = stopwatch.elapsed;
    if (elapsed < widget.minimumDisplay) {
      await Future<void>.delayed(widget.minimumDisplay - elapsed);
    }
    if (!mounted) return;
    if (error != null) {
      widget.onError?.call(context, error);
      return;
    }
    widget.onReady(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Scaffold(
      backgroundColor: colors.archbase.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.logo != null)
              widget.logo!
            else
              const FlutterLogo(size: 96),
            const SizedBox(height: 24),
            if (widget.appName != null)
              Text(
                widget.appName!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            if (widget.tagline != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.tagline!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
              ),
            ],
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            if (widget.versionLabel != null) ...[
              const SizedBox(height: 32),
              Text(
                widget.versionLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
