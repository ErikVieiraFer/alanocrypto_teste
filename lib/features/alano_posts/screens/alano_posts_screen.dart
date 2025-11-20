import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/alano_post_model.dart';
import '../../../services/alano_post_service.dart';
import '../../../widgets/haptic_button.dart';
import '../../../widgets/common/linkify_text.dart';
import '../../../theme/app_theme.dart';

class AlanoPostsScreen extends StatefulWidget {
  const AlanoPostsScreen({super.key});

  @override
  State<AlanoPostsScreen> createState() => _AlanoPostsScreenState();
}

class _AlanoPostsScreenState extends State<AlanoPostsScreen> {
  final AlanoPostService _alanoPostService = AlanoPostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openVideo(String? videoUrl) async {
    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link do vídeo não disponível'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(videoUrl);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível abrir: $videoUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir vídeo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return 'Hoje';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.video_library, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Conteúdo Exclusivo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AlanoPost>>(
              stream: _alanoPostService.getAlanoPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar posts: ${snapshot.error}'),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum conteúdo disponível ainda',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Novos vídeos em breve!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AlanoPostCard(
                          post: posts[index],
                          currentUserId: _auth.currentUser?.uid ?? '',
                          onVideoTap: _openVideo,
                          onViewIncrement: _alanoPostService.incrementViews,
                          formatTimestamp: _formatTimestamp,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AlanoPostCard extends StatelessWidget {
  final AlanoPost post;
  final String currentUserId;
  final Function(String?) onVideoTap;
  final Function(String) onViewIncrement;
  final String Function(DateTime) formatTimestamp;

  const AlanoPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onVideoTap,
    required this.onViewIncrement,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = post.likedBy.contains(currentUserId);

    return Container(
      decoration: AppTheme.modernCard(glowColor: AppTheme.primaryGreen),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppTheme.primaryGreen,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EXCLUSIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatTimestamp(post.createdAt),
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (post.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      LinkifyText(
                        text: post.content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Imagem do post (quando não há vídeo)
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty && post.videoUrl == null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _FullScreenImageViewer(
                          imageUrl: post.imageUrl!,
                        ),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: const Color.fromRGBO(224, 224, 224, 1.0),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: const Color.fromRGBO(224, 224, 224, 1.0),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Color.fromRGBO(158, 158, 158, 1.0),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Erro ao carregar imagem',
                            style: TextStyle(color: Color.fromRGBO(97, 97, 97, 1.0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Vídeo com thumbnail customizada
              if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    onVideoTap(post.videoUrl);
                    onViewIncrement(post.id);
                  },
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail customizada ou fallback
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: post.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.cardDark,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 80,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 80,
                              color: AppTheme.primaryGreen,
                            ),
                          ),

                        // Overlay escuro
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        // Ícone de play centralizado
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              size: 48,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),

                        // Badge "Vídeo" no canto superior direito
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 16,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vídeo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    LikeButton(
                      isLiked: isLiked,
                      likeCount: post.likedBy.length,
                      onPressed: () => AlanoPostService().toggleLike(post.id),
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.views}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Visualizador de imagem em tela cheia (estilo WhatsApp)
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Imagem centralizada com zoom
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          // Botão de fechar
          SafeArea(
            child: Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
