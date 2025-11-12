import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/news_article_model.dart';
import '../../../services/news_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_loading.dart';

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final NewsService _newsService = NewsService();
  List<NewsArticleModel> _news = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final news = await _newsService.getNews(limit: 6);
      if (mounted) {
        setState(() {
          _news = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.mobileHorizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.article, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 8),
                  Text('Notícias', style: AppTheme.heading2),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navegar para tela de notícias completa
                },
                child: Row(
                  children: [
                    Text(
                      'Ver Mais',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.primaryGreen,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.mobileHorizontalPadding),
          child: Text(
            'Fique por dentro das últimas tendências do mercado cripto, novidades sobre NFTs e oportunidades de investimento',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.gapLarge),
        SizedBox(
          height: 340,
          child: _isLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    left: AppTheme.mobileHorizontalPadding,
                    right: AppTheme.mobileHorizontalPadding,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) => const NewsCardShimmer(),
                )
              : _news.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma notícia disponível',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(
                        left: AppTheme.mobileHorizontalPadding,
                        right: AppTheme.mobileHorizontalPadding,
                      ),
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        return _NewsCard(article: _news[index]);
                      },
                    ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticleModel article;

  const _NewsCard({required this.article});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppTheme.mobileCardSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(article.url),
          borderRadius: AppTheme.largeRadius,
          splashColor: AppTheme.primaryGreen.withOpacity(0.1),
          child: Ink(
            decoration: AppTheme.glassCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.cardMedium,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.cardMedium,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppTheme.textSecondary,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (article.tags.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: article.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          article.title,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.gapSmall),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _launchUrl(article.url),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ler mais',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
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
      ),
    );
  }
}
