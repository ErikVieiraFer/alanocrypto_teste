import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/intro_video_model.dart';

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
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(18, 18, 18, 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(76, 175, 80, 1),
          ),
        ),
      );
    }

    if (_controller == null || _videoData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(18, 18, 18, 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color.fromRGBO(76, 175, 80, 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _videoData!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_videoData!.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _videoData!.description,
                    style: const TextStyle(
                      color: Color.fromRGBO(158, 158, 158, 1),
                      fontSize: 14,
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
