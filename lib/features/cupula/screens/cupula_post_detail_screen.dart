import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme/app_theme.dart';

/// Tela de detalhes do post premium
class CupulaPostDetailScreen extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const CupulaPostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  String get title => postData['title'] ?? '';
  String get excerpt => postData['excerpt'] ?? '';
  String get content => postData['content'] ?? '';
  String? get imageUrl => postData['imageUrl'];
  String get authorName => postData['authorName'] ?? 'Alano';
  int get views => postData['views'] ?? 0;

  DateTime? get createdAt {
    final timestamp = postData['createdAt'] as Timestamp?;
    return timestamp?.toDate();
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = createdAt != null
        ? timeago.format(createdAt!, locale: 'pt_BR')
        : '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem
          SliverAppBar(
            expandedHeight: imageUrl != null ? 250 : 0,
            pinned: true,
            backgroundColor: AppTheme.appBarColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share,
                    color: AppTheme.textPrimary,
                  ),
                ),
                onPressed: () => _sharePost(),
              ),
            ],
            flexibleSpace: imageUrl != null && imageUrl!.isNotEmpty
                ? FlexibleSpaceBar(
                    background: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardMedium,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.cardMedium,
                        child: const Center(
                          child: Icon(
                            Icons.article_rounded,
                            size: 80,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 14,
                              color: Colors.black,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Título
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Autor + Views
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        // Avatar do autor
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              authorName.isNotEmpty
                                  ? authorName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Autor',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Views
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              size: 18,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$views visualizações',
                              style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divisor
                  Container(
                    height: 1,
                    color: AppTheme.borderDark,
                  ),

                  const SizedBox(height: 24),

                  // Conteúdo do post (Markdown simples)
                  _buildContent(content),

                  const SizedBox(height: 40),

                  // Rodapé
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conteúdo Exclusivo',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Este conteúdo é exclusivo para membros premium da Cúpula.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renderiza o conteúdo com formatação básica de Markdown
  Widget _buildContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Headers
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(4),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ));
      }
      // Lista com bullet
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•  ',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: _buildFormattedText(line.substring(2)),
              ),
            ],
          ),
        ));
      }
      // Lista numerada
      else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.*)').firstMatch(line);
        if (match != null) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.group(1)}.  ',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: _buildFormattedText(match.group(2) ?? ''),
                ),
              ],
            ),
          ));
        }
      }
      // Texto normal
      else {
        widgets.add(_buildFormattedText(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Renderiza texto com formatação inline (bold, italic)
  Widget _buildFormattedText(String text) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    final italicRegex = RegExp(r'\*(.+?)\*');

    String remaining = text;

    while (remaining.isNotEmpty) {
      final boldMatch = boldRegex.firstMatch(remaining);
      final italicMatch = italicRegex.firstMatch(remaining);

      Match? firstMatch;
      bool isBold = false;

      if (boldMatch != null && italicMatch != null) {
        if (boldMatch.start <= italicMatch.start) {
          firstMatch = boldMatch;
          isBold = true;
        } else {
          firstMatch = italicMatch;
        }
      } else if (boldMatch != null) {
        firstMatch = boldMatch;
        isBold = true;
      } else if (italicMatch != null) {
        firstMatch = italicMatch;
      }

      if (firstMatch != null) {
        if (firstMatch.start > 0) {
          spans.add(TextSpan(
            text: remaining.substring(0, firstMatch.start),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ));
        }

        spans.add(TextSpan(
          text: firstMatch.group(1),
          style: TextStyle(
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 16,
            height: 1.6,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isBold ? FontStyle.normal : FontStyle.italic,
          ),
        ));

        remaining = remaining.substring(firstMatch.end);
      } else {
        spans.add(TextSpan(
          text: remaining,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            height: 1.6,
          ),
        ));
        break;
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _sharePost() {
    Share.share(
      '$title\n\n$excerpt\n\n🔗 Conteúdo exclusivo da Cúpula - AlanoCryptoFX',
      subject: title,
    );
  }
}
