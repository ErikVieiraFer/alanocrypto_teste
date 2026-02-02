import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class AudioRecorderWidget extends StatefulWidget {
  final Function(dynamic audioData, int durationSeconds) onRecordingComplete;
  final VoidCallback onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  RecorderState _state = RecorderState.idle;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordedPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        String path;

        if (kIsWeb) {
          path = '';
        } else {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        final config = kIsWeb
            ? const RecordConfig(
                encoder: AudioEncoder.opus,
                bitRate: 128000,
                sampleRate: 48000,
              )
            : const RecordConfig(
                encoder: AudioEncoder.aacLc,
                bitRate: 128000,
                sampleRate: 44100,
              );

        await _recorder.start(config, path: path);

        setState(() {
          _state = RecorderState.recording;
          _recordingSeconds = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        _showError('Permissão de microfone negada');
      }
    } catch (e) {
      _showError('Erro ao iniciar gravação');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final savedDuration = _recordingSeconds;

    try {
      final path = await _recorder.stop();
      debugPrint('🎤 Gravação parada. Path: $path');

      if (path != null && path.isNotEmpty) {
        setState(() {
          _recordedPath = path;
          _recordingSeconds = savedDuration;
          _state = RecorderState.preview;
        });
        debugPrint('🎤 Estado mudou para preview');
      } else {
        debugPrint('🎤 Path é null ou vazio, mantendo duração: $savedDuration');
        setState(() {
          _recordingSeconds = savedDuration;
          _state = RecorderState.preview;
          _recordedPath = 'web_recording';
        });
      }
    } catch (e) {
      debugPrint('🎤 Erro ao parar gravação: $e');
      _showError('Erro ao parar gravação: $e');
      setState(() {
        _state = RecorderState.idle;
      });
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();

    try {
      await _recorder.cancel();
    } catch (_) {}

    setState(() {
      _state = RecorderState.idle;
      _recordingSeconds = 0;
      _recordedPath = null;
    });
  }

  Future<void> _playPreview() async {
    if (_recordedPath == null) return;

    try {
      setState(() {
        _state = RecorderState.playing;
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _state = RecorderState.preview;
          });
        }
      });

      if (kIsWeb) {
        await _audioPlayer.play(UrlSource(_recordedPath!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordedPath!));
      }
    } catch (e) {
      setState(() {
        _state = RecorderState.preview;
      });
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer.stop();
    setState(() {
      _state = RecorderState.preview;
    });
  }

  Future<void> _confirmRecording() async {
    debugPrint('🎤 _confirmRecording chamado. Path: $_recordedPath, Duration: $_recordingSeconds');

    final duration = _recordingSeconds;

    if (duration <= 0) {
      _showError('Gravação muito curta');
      return;
    }

    try {
      await _audioPlayer.stop();

      dynamic audioData;

      if (kIsWeb) {
        audioData = _recordedPath ?? 'web_audio';
        debugPrint('🎤 Web: enviando path como audioData: $audioData');
      } else {
        if (_recordedPath == null) {
          _showError('Nenhuma gravação encontrada');
          return;
        }
        final file = File(_recordedPath!);
        if (!await file.exists()) {
          _showError('Arquivo de áudio não encontrado');
          return;
        }
        audioData = await file.readAsBytes();
        debugPrint('🎤 Mobile: leu ${(audioData as Uint8List).length} bytes');
      }

      debugPrint('🎤 Chamando onRecordingComplete com duração: $duration');
      widget.onRecordingComplete(audioData, duration);
    } catch (e) {
      debugPrint('🎤 Erro ao confirmar gravação: $e');
      _showError('Erro ao processar áudio: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kNeonGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _kNeonGreen.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                color: _kNeonGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _state == RecorderState.idle
                    ? 'Gravar áudio'
                    : _state == RecorderState.recording
                        ? 'Gravando...'
                        : 'Prévia do áudio',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _cancelRecording();
                  widget.onCancel();
                },
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case RecorderState.idle:
        return _buildIdleState();
      case RecorderState.recording:
        return _buildRecordingState();
      case RecorderState.preview:
      case RecorderState.playing:
        return _buildPreviewState();
    }
  }

  Widget _buildIdleState() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kNeonGreen,
              _kNeonGreen.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kNeonGreen.withValues(alpha: 0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: Colors.black,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        Text(
          _formatDuration(_recordingSeconds),
          style: const TextStyle(
            color: _kNeonGreen,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        _buildWaveform(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kNeonGreen,
                      _kNeonGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kNeonGreen.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (index) {
        final height = 8.0 + (index % 5) * 6.0 + (_recordingSeconds % 3) * 4.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 3,
          height: height.clamp(8.0, 32.0),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _kNeonGreen.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildPreviewState() {
    final isPlaying = _state == RecorderState.playing;

    return Column(
      children: [
        Text(
          _formatDuration(_recordingSeconds),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: isPlaying ? _stopPreview : _playPreview,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _confirmRecording,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kNeonGreen,
                      _kNeonGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kNeonGreen.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum RecorderState {
  idle,
  recording,
  preview,
  playing,
}
