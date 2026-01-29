import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/cupula_posts_service.dart';
import '../widgets/cupula_widgets.dart';
import 'cupula_post_detail_screen.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class CupulaPostsPreview extends StatefulWidget {
  const CupulaPostsPreview({super.key});

  @override
  State<CupulaPostsPreview> createState() => _CupulaPostsPreviewState();
}

class _CupulaPostsPreviewState extends State<CupulaPostsPreview>
    with SingleTickerProviderStateMixin {
  final CupulaPostsService _postsService = CupulaPostsService();
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsService.getPosts(),
              builder: (context, snapshot) {
                debugPrint('📰 StreamBuilder state: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  debugPrint('❌ StreamBuilder error: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  debugPrint('✅ Posts carregados: ${snapshot.data!.docs.length}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

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

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _PostCard(
                        postId: doc.id,
                        title: data['title'] ?? '',
                        excerpt: data['excerpt'] ?? '',
                        imageUrl: data['imageUrl'],
                        authorName: data['authorName'] ?? 'Alano',
                        createdAt: data['createdAt'] as Timestamp?,
                        views: data['views'] ?? 0,
                      ),
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
    return FadeTransition(
      opacity: _headerFadeAnim,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _kNeonGreen.withValues(alpha: 0.15),
              _kNeonGreen.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: _kNeonGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kNeonGreen.withValues(alpha: 0.3),
                      _kNeonGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kNeonGreen.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kNeonGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: _kNeonGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posts Premium',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conteúdo exclusivo da Cúpula',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatsChip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsChip() {
    return StreamBuilder<QuerySnapshot>(
      stream: _postsService.getPosts(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kNeonGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _kNeonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_rounded,
                color: _kNeonGreen,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$count posts',
                style: const TextStyle(
                  color: _kNeonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + index * 100),
          builder: (context, value, child) {
            return Opacity(
              opacity: value * 0.5,
              child: child,
            );
          },
          child: Padding(
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erro ao carregar posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNeonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kNeonGreen.withValues(alpha: 0.2),
                    _kNeonGreen.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 48,
                color: _kNeonGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum post exclusivo ainda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posts premium serão publicados aqui.\nAguarde novos conteúdos!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String postId;
  final String title;
  final String excerpt;
  final String? imageUrl;
  final String authorName;
  final Timestamp? createdAt;
  final int views;

  const _PostCard({
    required this.postId,
    required this.title,
    required this.excerpt,
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
              color: _kNeonGreen.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem com overlay
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.cardMedium,
                                    AppTheme.cardDark,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 48,
                                  color: _kNeonGreen.withValues(alpha: 0.3),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _kNeonGreen,
                              _kNeonGreen.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _kNeonGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 12,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Excerpt
                    Text(
                      excerpt,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Metadata
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: _kNeonGreen.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            authorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.visibility_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$views',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
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
