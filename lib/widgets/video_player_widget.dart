import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_theme.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showThumbnail = true;

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (_videoController != null) return;

    setState(() {
      _showThumbnail = false;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: _kNeonGreen,
          handleColor: _kNeonGreen,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          bufferedColor: _kNeonGreen.withValues(alpha: 0.3),
        ),
        placeholder: Container(
          color: AppTheme.cardDark,
          child: const Center(
            child: CircularProgressIndicator(
              color: _kNeonGreen,
              strokeWidth: 2,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: AppTheme.cardDark,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.withValues(alpha: 0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erro ao carregar vídeo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kNeonGreen.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_showThumbnail) {
      return _buildThumbnailState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return _buildPlayerState();
  }

  Widget _buildThumbnailState() {
    return GestureDetector(
      onTap: _initializePlayer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.thumbnailUrl != null)
            Image.network(
              widget.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: AppTheme.cardDark,
                  child: Icon(
                    Icons.videocam_rounded,
                    color: _kNeonGreen.withValues(alpha: 0.5),
                    size: 64,
                  ),
                );
              },
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              color: AppTheme.cardDark,
              child: Icon(
                Icons.videocam_rounded,
                color: _kNeonGreen.withValues(alpha: 0.5),
                size: 64,
              ),
            ),
          Container(
            width: 64,
            height: 64,
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
              Icons.play_arrow_rounded,
              color: Colors.black,
              size: 36,
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_rounded,
                    color: _kNeonGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.durationSeconds != null
                        ? _formatDuration(widget.durationSeconds!)
                        : 'Vídeo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppTheme.cardDark,
      child: const Center(
        child: CircularProgressIndicator(
          color: _kNeonGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPlayerState() {
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppTheme.cardDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.withValues(alpha: 0.8),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Erro ao carregar vídeo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _hasError = false;
                  _showThumbnail = true;
                  _videoController?.dispose();
                  _chewieController?.dispose();
                  _videoController = null;
                  _chewieController = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kNeonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _kNeonGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: _kNeonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
