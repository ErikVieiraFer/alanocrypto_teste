import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../models/intro_video_model.dart';
import '../../../theme/app_theme.dart';

class IntroVideoSection extends StatefulWidget {
  final bool isDrawerOpen;
  final bool isDialogOpen;

  const IntroVideoSection({
    super.key,
    this.isDrawerOpen = false,
    this.isDialogOpen = false,
  });

  @override
  State<IntroVideoSection> createState() => _IntroVideoSectionState();
}

class _IntroVideoSectionState extends State<IntroVideoSection> {
  YoutubePlayerController? _controller;
  IntroVideoModel? _videoData;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    return null;
  }

  Future<void> _loadVideoData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('intro_video')
          .get();

      if (doc.exists) {
        final videoModel = IntroVideoModel.fromFirestore(doc);

        if (videoModel.isActive && videoModel.videoUrl.isNotEmpty) {
          final videoId = _extractVideoId(videoModel.videoUrl);

          if (videoId != null && !_isDisposed) {
            final controller = YoutubePlayerController.fromVideoId(
              videoId: videoId,
              autoPlay: false,
              params: const YoutubePlayerParams(
                showControls: true,
                mute: false,
                showFullscreenButton: true,
                loop: false,
              ),
            );

            if (mounted) {
              setState(() {
                _videoData = videoModel;
                _controller = controller;
                _isLoading = false;
              });
            }
          }
        }
      }

      if (_controller == null && mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erro ao carregar vídeo: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.mobileHorizontalPadding),
        decoration: AppTheme.cardDecoration(),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
      );
    }

    if (_controller == null || _videoData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: AppTheme.gradientCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: YoutubePlayer(
              controller: _controller!,
              aspectRatio: 16 / 9,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_videoData!.title, style: AppTheme.heading3),
                if (_videoData!.description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.gapSmall),
                  Text(
                    _videoData!.description,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
