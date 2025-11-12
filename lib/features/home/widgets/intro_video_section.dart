import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/intro_video_model.dart';
import '../../../theme/app_theme.dart';

class IntroVideoSection extends StatefulWidget {
  const IntroVideoSection({super.key});

  @override
  State<IntroVideoSection> createState() => _IntroVideoSectionState();
}

class _IntroVideoSectionState extends State<IntroVideoSection> {
  YoutubePlayerController? _controller;
  IntroVideoModel? _videoData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideoData();
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
          final videoId = YoutubePlayer.convertUrlToId(videoModel.videoUrl);

          if (videoId != null) {
            setState(() {
              _videoData = videoModel;
              _controller = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  enableCaption: false,
                ),
              );
              _isLoading = false;
            });
          }
        }
      }

      if (_controller == null) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.mobileHorizontalPadding),
      decoration: AppTheme.gradientCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppTheme.primaryGreen,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _videoData!.title,
                  style: AppTheme.heading3,
                ),
                if (_videoData!.description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.gapSmall),
                  Text(
                    _videoData!.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
