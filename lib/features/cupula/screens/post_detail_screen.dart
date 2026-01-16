import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/cupula_posts_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CupulaPostsService _postsService = CupulaPostsService();

  @override
  void initState() {
    super.initState();
    // Incrementar views ao abrir
    _postsService.incrementViews(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: const Text('Post'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _postsService.getPost(widget.postId),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Erro
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Erro ao carregar post',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem de capa
                if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                  Image.network(
                    data['imageUrl'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: AppTheme.cardMedium,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge categoria
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(data['category']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['category'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Metadata
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryGreen,
                            child: Text(
                              (data['authorName'] ?? 'A')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['authorName'] ?? 'Autor',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _formatDate(data['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Views
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${data['views'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: AppTheme.borderDark.withOpacity(0.3)),
                      const SizedBox(height: 24),

                      // Conteúdo (Markdown)
                      MarkdownBody(
                        data: data['content'] ?? '',
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            height: 1.6,
                          ),
                          h1: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          h2: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          h3: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          listBullet: const TextStyle(
                            color: AppTheme.primaryGreen,
                          ),
                          code: TextStyle(
                            backgroundColor: AppTheme.cardMedium,
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppTheme.cardMedium,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 4,
                              ),
                            ),
                          ),
                          blockquotePadding: const EdgeInsets.only(left: 16),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          em: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textPrimary,
                          ),
                          a: const TextStyle(
                            color: AppTheme.primaryGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        selectable: true,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String? category) {
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
