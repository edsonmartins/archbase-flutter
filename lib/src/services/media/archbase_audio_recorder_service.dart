import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/state/archbase_service.dart';

class ArchbaseAudioFile {
  ArchbaseAudioFile({required this.path, required this.duration});

  final String path;
  final Duration duration;

  File asFile() => File(path);
}

/// Encapsula gravação e reprodução de áudio.
///
/// - Grava em M4A/AAC (`.m4a`) por padrão
/// - Limite máximo de duração configurável
/// - Expõe amplitude em tempo real para visualizador
/// - Player com posição e duração observáveis
class ArchbaseAudioRecorderService extends ArchbaseService {
  ArchbaseAudioRecorderService({
    AudioRecorder? recorder,
    AudioPlayer? player,
    this.maxDuration = const Duration(seconds: 120),
    this.encoder = AudioEncoder.aacLc,
    this.bitRate = 128000,
    this.sampleRate = 44100,
  })  : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final Duration maxDuration;
  final AudioEncoder encoder;
  final int bitRate;
  final int sampleRate;

  final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> elapsed =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> playerPosition =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> playerDuration =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<double> amplitude = ValueNotifier<double>(0);

  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _ticker;
  String? _currentPath;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;

  @override
  Future<void> onInit() async {
    _posSub = _player.onPositionChanged.listen((d) => playerPosition.value = d);
    _durSub = _player.onDurationChanged.listen((d) => playerDuration.value = d);
    _completeSub = _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      playerPosition.value = Duration.zero;
    });
  }

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String> _newRecordingPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/rec_$ts.m4a';
  }

  Future<void> startRecording() async {
    if (isRecording.value) return;
    final ok = await hasPermission();
    if (!ok) throw StateError('Sem permissão para gravar áudio');

    _currentPath = await _newRecordingPath();
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        bitRate: bitRate,
        sampleRate: sampleRate,
      ),
      path: _currentPath!,
    );

    isRecording.value = true;
    elapsed.value = Duration.zero;

    final start = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      final delta = DateTime.now().difference(start);
      elapsed.value = delta;
      if (delta >= maxDuration) {
        await stopRecording();
      }
    });
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((amp) {
      // amp.current vem em dBFS (negativo). Normaliza para 0..1.
      const minDb = -45.0;
      final normalized = ((amp.current - minDb) / -minDb).clamp(0.0, 1.0);
      amplitude.value = normalized;
    });
  }

  Future<ArchbaseAudioFile?> stopRecording() async {
    if (!isRecording.value) return null;
    final path = await _recorder.stop();
    isRecording.value = false;
    _ticker?.cancel();
    await _amplitudeSub?.cancel();
    amplitude.value = 0;
    final duration = elapsed.value;
    elapsed.value = Duration.zero;
    if (path == null) return null;
    return ArchbaseAudioFile(path: path, duration: duration);
  }

  Future<void> cancelRecording() async {
    if (!isRecording.value) return;
    await _recorder.cancel();
    isRecording.value = false;
    _ticker?.cancel();
    await _amplitudeSub?.cancel();
    if (_currentPath != null) {
      try {
        await File(_currentPath!).delete();
      } catch (_) {}
    }
    elapsed.value = Duration.zero;
    amplitude.value = 0;
  }

  Future<void> play(String path) async {
    if (isPlaying.value) {
      await _player.pause();
    }
    await _player.play(DeviceFileSource(path));
    isPlaying.value = true;
  }

  Future<void> pausePlayback() async {
    await _player.pause();
    isPlaying.value = false;
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    isPlaying.value = false;
    playerPosition.value = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> onDispose() async {
    _ticker?.cancel();
    await _amplitudeSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _completeSub?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    isRecording.dispose();
    isPlaying.dispose();
    elapsed.dispose();
    playerPosition.dispose();
    playerDuration.dispose();
    amplitude.dispose();
  }

  /// Helper para formatar Duration como `mm:ss`.
  static String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (kDebugMode && d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}
