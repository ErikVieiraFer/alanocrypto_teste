import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewsApiService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const String _cacheKey = 'cached_news';
  static const String _cacheTimeKey = 'cached_news_time';
  static const Duration _cacheDuration = Duration(hours: 3);

  final String apiKey;

  NewsApiService({required this.apiKey});

  Future<List<NewsArticle>> getFinancialNews() async {
    // Verificar cache primeiro
    final cachedNews = await _getCachedNews();
    if (cachedNews != null) {
      print('📦 Usando ${cachedNews.length} notícias do cache');
      return cachedNews;
    }

    // Se não tem cache válido, buscar da API
    try {
      print('🔍 Iniciando busca de notícias...');
      print('🔑 API Key: ${apiKey.substring(0, min(5, apiKey.length))}...');

      final url = '$_baseUrl?function=NEWS_SENTIMENT&tickers=COIN,CRYPTO:BTC,FOREX:USD&apikey=$apiKey';
      print('🔗 URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Status code: ${response.statusCode}');
      print('📄 Response body (primeiros 200 chars): ${response.body.substring(0, min(200, response.body.length))}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificar se há erro na resposta da API
        if (data.containsKey('Error Message')) {
          print('❌ Erro da API: ${data['Error Message']}');
          return [];
        }

        if (data.containsKey('Note')) {
          print('⚠️ Rate limit: ${data['Note']}');
          return [];
        }

        final feed = data['feed'] as List?;

        if (feed == null || feed.isEmpty) {
          print('⚠️ Feed vazio ou nulo');
          return [];
        }

        print('✅ ${feed.length} notícias encontradas');

        final articles = feed.take(10).map((article) {
          return NewsArticle(
            title: article['title'] ?? '',
            summary: article['summary'] ?? '',
            url: article['url'] ?? '',
            imageUrl: article['banner_image'],
            publishedAt: DateTime.parse(article['time_published'] ?? DateTime.now().toIso8601String()),
            source: article['source'] ?? 'Financial News',
          );
        }).toList();

        // Cachear resultados
        await _cacheNews(articles);

        return articles;
      } else {
        print('❌ Falha na requisição: ${response.statusCode}');
        print('📄 Body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar notícias: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<NewsArticle>?> _getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final cachedTime = prefs.getInt(_cacheTimeKey);

      if (cachedJson != null && cachedTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cachedTime);

        if (DateTime.now().difference(cacheDateTime) < _cacheDuration) {
          final List<dynamic> decoded = json.decode(cachedJson);
          return decoded.map((item) => NewsArticle.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('Error loading cached news: $e');
    }
    return null;
  }

  Future<void> _cacheNews(List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((article) => article.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching news: $e');
    }
  }
}

class NewsArticle {
  final String title;
  final String summary;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.summary,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'url': url,
    'imageUrl': imageUrl,
    'publishedAt': publishedAt.toIso8601String(),
    'source': source,
  };

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    title: json['title'],
    summary: json['summary'],
    url: json['url'],
    imageUrl: json['imageUrl'],
    publishedAt: DateTime.parse(json['publishedAt']),
    source: json['source'],
  );
}
