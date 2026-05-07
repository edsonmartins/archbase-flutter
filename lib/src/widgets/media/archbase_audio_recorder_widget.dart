import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/media/archbase_audio_recorder_service.dart';
import '../../theme/archbase_theme_extensions.dart';

/// Widget completo de gravação + reprodução de áudio.
///
/// Estados:
/// - **Idle**: botão de mic
/// - **Recording**: timer + visualizador de amplitude + stop/cancel
/// - **Playback**: play/pause + progresso + delete
class ArchbaseAudioRecorderWidget extends StatefulWidget {
  const ArchbaseAudioRecorderWidget({
    super.key,
    required this.service,
    this.onRecorded,
    this.initialPath,
    this.onDeleted,
  });

  final ArchbaseAudioRecorderService service;
  final ValueChanged<ArchbaseAudioFile>? onRecorded;
  final VoidCallback? onDeleted;
  final String? initialPath;

  @override
  State<ArchbaseAudioRecorderWidget> createState() =>
      _ArchbaseAudioRecorderWidgetState();
}

class _ArchbaseAudioRecorderWidgetState
    extends State<ArchbaseAudioRecorderWidget> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.service.isRecording,
          builder: (_, isRec, __) {
            if (isRec) return _RecordingView(service: widget.service, onStop: _onStop);
            if (_path != null) {
              return _PlaybackView(
                service: widget.service,
                path: _path!,
                onDelete: _onDelete,
              );
            }
            return _IdleView(onStart: _onStart);
          },
        ),
      ),
    );
  }

  Future<void> _onStart() async {
    try {
      await widget.service.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao gravar: $e')),
        );
      }
    }
  }

  Future<void> _onStop() async {
    final file = await widget.service.stopRecording();
    if (file != null) {
      setState(() => _path = file.path);
      widget.onRecorded?.call(file);
    }
  }

  void _onDelete() {
    setState(() => _path = null);
    widget.onDeleted?.call();
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.mic),
        const SizedBox(width: 12),
        const Expanded(child: Text('Toque para gravar um áudio')),
        IconButton.filled(
          icon: const Icon(LucideIcons.mic),
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({required this.service, required this.onStop});
  final ArchbaseAudioRecorderService service;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbaseColors;
    return Column(
      children: [
        Row(
          children: [
            Icon(LucideIcons.circle, color: colors.error, size: 12),
            const SizedBox(width: 8),
            ValueListenableBuilder<Duration>(
              valueListenable: service.elapsed,
              builder: (_, e, __) => Text(
                ArchbaseAudioRecorderService.formatDuration(e),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () => service.cancelRecording(),
              tooltip: 'Cancelar',
            ),
            IconButton.filled(
              icon: const Icon(LucideIcons.square),
              onPressed: onStop,
              tooltip: 'Parar',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ValueListenableBuilder<double>(
            valueListenable: service.amplitude,
            builder: (_, amp, __) => _AmplitudeBars(amplitude: amp),
          ),
        ),
      ],
    );
  }
}

class _PlaybackView extends StatelessWidget {
  const _PlaybackView({
    required this.service,
    required this.path,
    required this.onDelete,
  });

  final ArchbaseAudioRecorderService service;
  final String path;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.isPlaying,
      builder: (_, playing, __) {
        return Row(
          children: [
            IconButton.filled(
              icon: Icon(playing ? LucideIcons.pause : LucideIcons.play),
              onPressed: () =>
                  playing ? service.pausePlayback() : service.play(path),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<Duration>(
                valueListenable: service.playerPosition,
                builder: (_, pos, __) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: service.playerDuration,
                    builder: (_, dur, __) {
                      final ratio = dur.inMilliseconds == 0
                          ? 0.0
                          : pos.inMilliseconds / dur.inMilliseconds;
                      return Column(
                        children: [
                          LinearProgressIndicator(value: ratio.clamp(0.0, 1.0)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ArchbaseAudioRecorderService.formatDuration(pos),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                ArchbaseAudioRecorderService.formatDuration(dur),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              onPressed: onDelete,
            ),
          ],
        );
      },
    );
  }
}

class _AmplitudeBars extends StatelessWidget {
  const _AmplitudeBars({required this.amplitude});

  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbaseColors;
    const bars = 24;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(bars, (i) {
        final phase = (i / bars + amplitude) % 1.0;
        final h = 6 + (amplitude * 26 * (0.4 + phase * 0.6));
        return Container(
          width: 3,
          height: h.clamp(4, 32),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
