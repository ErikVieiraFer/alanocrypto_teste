import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewsApiService {
  static const String _cloudFunctionUrl =
    'https://getnews-yoas3thzsq-uc.a.run.app';

  List<NewsArticle> _getMockNews() {
    print('📰 Usando notícias mockadas como fallback');

    final now = DateTime.now();

    return [
      NewsArticle(
        title: 'Bitcoin ultrapassa US\$ 94.000 em nova máxima histórica',
        summary: 'Criptomoeda registra valorização de 15% na semana impulsionada por fatores macroeconômicos favoráveis e maior adoção institucional.',
        url: 'https://www.coindesk.com',
        imageUrl: 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 2)),
        source: 'CoinDesk',
      ),
      NewsArticle(
        title: 'Ethereum implementa atualização de escalabilidade',
        summary: 'Nova atualização promete reduzir taxas em até 70% e aumentar velocidade de transações na rede Ethereum.',
        url: 'https://www.coindesk.com',
        imageUrl: 'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 5)),
        source: 'CoinTelegraph',
      ),
      NewsArticle(
        title: 'Dólar cai 1,2% frente ao Real após decisão do BC',
        summary: 'Moeda americana recua com manutenção da Selic em 10,75% ao ano pelo Banco Central.',
        url: 'https://www.infomoney.com.br',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 8)),
        source: 'InfoMoney',
      ),
      NewsArticle(
        title: 'Ouro atinge US\$ 2.100 com tensões geopolíticas',
        summary: 'Metal precioso valoriza 3% no dia com investidores buscando ativos de proteção.',
        url: 'https://www.bloomberg.com',
        imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 12)),
        source: 'Bloomberg',
      ),
      NewsArticle(
        title: 'Bolsas americanas fecham em alta generalizada',
        summary: 'S&P 500 e Nasdaq registram ganhos com balanços corporativos acima das expectativas.',
        url: 'https://www.cnbc.com',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 18)),
        source: 'CNBC',
      ),
      NewsArticle(
        title: 'EUR/USD testa resistência em zona de 1,0950',
        summary: 'Par de moedas busca romper barreira técnica importante após semana volátil.',
        url: 'https://www.investing.com',
        imageUrl: 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=800&q=80',
        publishedAt: now.subtract(const Duration(hours: 24)),
        source: 'Investing.com',
      ),
    ];
  }

  Future<List<NewsArticle>> getFinancialNews() async {
    // Verificar cache
    final cachedNews = await _getCachedNews();
    if (cachedNews != null && cachedNews.isNotEmpty) {
      print('📦 Usando notícias do cache (${cachedNews.length} artigos)');
      return cachedNews;
    }

    try {
      print('🔍 Buscando notícias via Cloud Function...');
      print('🔗 URL: $_cloudFunctionUrl');

      final response = await http.get(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📄 Response keys: ${data.keys.toList()}');

        // Verificar rate limit
        if (data.containsKey('Information')) {
          print('⚠️ Alpha Vantage rate limit: ${data['Information']}');
          print('💡 Usando notícias mockadas como fallback');
          final mockNews = _getMockNews();
          await _cacheNews(mockNews);
          return mockNews;
        }

        // Verificar erro
        if (data.containsKey('Error Message')) {
          print('❌ Erro da API: ${data['Error Message']}');
          print('💡 Usando notícias mockadas como fallback');
          final mockNews = _getMockNews();
          await _cacheNews(mockNews);
          return mockNews;
        }

        // Verificar feed
        if (data.containsKey('feed') && data['feed'] is List) {
          final List<dynamic> feed = data['feed'];

          if (feed.isEmpty) {
            print('⚠️ API retornou 0 artigos');
            print('💡 Usando notícias mockadas como fallback');
            final mockNews = _getMockNews();
            await _cacheNews(mockNews);
            return mockNews;
          }

          print('✅ ${feed.length} notícias encontradas na API');

          final articles = feed.take(10).map((article) {
            return NewsArticle(
              title: article['title'] ?? '',
              summary: article['summary'] ?? '',
              url: article['url'] ?? '',
              imageUrl: article['banner_image'],
              publishedAt: DateTime.parse(
                article['time_published'] ?? DateTime.now().toIso8601String()
              ),
              source: article['source'] ?? 'Financial News',
            );
          }).toList();

          await _cacheNews(articles);
          return articles;
        } else {
          print('⚠️ Resposta sem campo "feed" válido');
          print('💡 Usando notícias mockadas como fallback');
          final mockNews = _getMockNews();
          await _cacheNews(mockNews);
          return mockNews;
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('💡 Usando notícias mockadas como fallback');
        final mockNews = _getMockNews();
        await _cacheNews(mockNews);
        return mockNews;
      }
    } catch (e) {
      print('❌ Erro ao buscar notícias: $e');
      print('💡 Usando notícias mockadas como fallback');
      final mockNews = _getMockNews();
      await _cacheNews(mockNews);
      return mockNews;
    }
  }

  Future<List<NewsArticle>?> _getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_news');
      final cacheTime = prefs.getInt('cache_time');

      if (cachedData != null && cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - cacheTime < 3 * 60 * 60 * 1000) {
          final List<dynamic> decoded = json.decode(cachedData);
          return decoded.map((item) => NewsArticle.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('⚠️ Erro ao ler cache: $e');
    }
    return null;
  }

  Future<void> _cacheNews(List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((a) => a.toJson()).toList();
      await prefs.setString('cached_news', json.encode(jsonList));
      await prefs.setInt('cache_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('⚠️ Erro ao salvar cache: $e');
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

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'],
      summary: json['summary'],
      url: json['url'],
      imageUrl: json['imageUrl'],
      publishedAt: DateTime.parse(json['publishedAt']),
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'source': source,
    };
  }
}
