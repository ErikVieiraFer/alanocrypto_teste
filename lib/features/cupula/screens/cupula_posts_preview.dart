import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/cupula_posts_service.dart';
import '../widgets/cupula_widgets.dart';
import 'cupula_post_detail_screen.dart';

class CupulaPostsPreview extends StatefulWidget {
  const CupulaPostsPreview({super.key});

  @override
  State<CupulaPostsPreview> createState() => _CupulaPostsPreviewState();
}

class _CupulaPostsPreviewState extends State<CupulaPostsPreview> {
  final CupulaPostsService _postsService = CupulaPostsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header simples (sem filtros)
          _buildHeader(),

          // Lista de posts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsService.getPosts(),
              builder: (context, snapshot) {
                // DEBUG
                debugPrint('📰 StreamBuilder state: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  debugPrint('❌ StreamBuilder error: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  debugPrint('✅ Posts carregados: ${snapshot.data!.docs.length}');
                }

                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                // Erro
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                // Vazio
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _PostCard(
                      postId: doc.id,
                      title: data['title'] ?? '',
                      excerpt: data['excerpt'] ?? '',
                      category: data['category'] ?? '',
                      imageUrl: data['imageUrl'],
                      authorName: data['authorName'] ?? 'Alano',
                      createdAt: data['createdAt'] as Timestamp?,
                      views: data['views'] ?? 0,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.article, color: AppTheme.primaryGreen, size: 24),
          SizedBox(width: 12),
          Text(
            'Posts Premium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 180,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoader(width: 100, height: 16),
                      SizedBox(height: 12),
                      SkeletonLoader(width: double.infinity, height: 20),
                      SizedBox(height: 8),
                      SkeletonLoader(width: double.infinity, height: 14),
                      SkeletonLoader(width: 200, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String errorMessage) {
    debugPrint('🔴 Erro na tela de posts: $errorMessage');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar posts',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum post exclusivo ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Posts premium serão publicados aqui.\nAguarde novos conteúdos!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de post individual
class _PostCard extends StatelessWidget {
  final String postId;
  final String title;
  final String excerpt;
  final String category;
  final String? imageUrl;
  final String authorName;
  final Timestamp? createdAt;
  final int views;

  const _PostCard({
    required this.postId,
    required this.title,
    required this.excerpt,
    required this.category,
    this.imageUrl,
    required this.authorName,
    this.createdAt,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    final date = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CupulaPostDetailScreen(
                postId: postId,
                postData: {
                  'title': title,
                  'excerpt': excerpt,
                  'category': category,
                  'imageUrl': imageUrl,
                  'authorName': authorName,
                  'createdAt': createdAt,
                  'views': views,
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderDark.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem
              if (imageUrl != null && imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: AppTheme.cardMedium,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge categoria
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Título
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Excerpt
                    Text(
                      excerpt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Metadata
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.visibility, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$views',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Estratégia':
        return AppTheme.successGreen;
      case 'Análise':
        return AppTheme.infoBlue;
      case 'Educação':
        return AppTheme.warningOrange;
      default:
        return AppTheme.primaryGreen;
    }
  }
}
