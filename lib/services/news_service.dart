import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article_model.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NewsArticleModel>> getNewsStream({int limit = 6}) {
    // Ler do cache market_cache/news
    return _firestore
        .collection('market_cache')
        .doc('news')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return <NewsArticleModel>[];

      final data = doc.data()!;
      final List<dynamic> newsData = data['data'] ?? [];

      return newsData
          .take(limit)
          .map((item) => _parseNewsFromCache(item))
          .toList();
    });
  }

  Future<List<NewsArticleModel>> getNews({int limit = 6}) async {
    try {
      final doc = await _firestore
          .collection('market_cache')
          .doc('news')
          .get();

      if (!doc.exists || doc.data() == null) return [];

      final data = doc.data()!;
      final List<dynamic> newsData = data['data'] ?? [];

      return newsData
          .take(limit)
          .map((item) => _parseNewsFromCache(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  NewsArticleModel _parseNewsFromCache(dynamic item) {
    final map = item as Map<String, dynamic>;

    // Parse da data
    DateTime publishedAt;
    try {
      if (map['publishedAt'] is String) {
        publishedAt = DateTime.parse(map['publishedAt']);
      } else if (map['publishedAt'] is Timestamp) {
        publishedAt = (map['publishedAt'] as Timestamp).toDate();
      } else {
        publishedAt = DateTime.now();
      }
    } catch (e) {
      publishedAt = DateTime.now();
    }

    return NewsArticleModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      imageUrl: map['urlToImage']?.toString() ?? '',
      tags: [map['source']?.toString() ?? 'News'],
      url: map['url']?.toString() ?? '',
      isPremium: false,
      publishedAt: publishedAt,
    );
  }

  Future<List<NewsArticleModel>> getAllNews() async {
    try {
      final doc = await _firestore
          .collection('market_cache')
          .doc('news')
          .get();

      if (!doc.exists || doc.data() == null) return [];

      final data = doc.data()!;
      final List<dynamic> newsData = data['data'] ?? [];

      return newsData
          .map((item) => _parseNewsFromCache(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching all news: $e');
    }
  }

  Future<NewsArticleModel> getNewsById(String id) async {
    try {
      final doc = await _firestore.collection('news').doc(id).get();
      if (!doc.exists) {
        throw Exception('News article not found');
      }
      return NewsArticleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error fetching news article: $e');
    }
  }

  Future<void> createNews(NewsArticleModel article) async {
    try {
      await _firestore.collection('news').add(article.toFirestore());
    } catch (e) {
      throw Exception('Error creating news: $e');
    }
  }

  Future<void> updateNews(String id, NewsArticleModel article) async {
    try {
      await _firestore.collection('news').doc(id).update(article.toFirestore());
    } catch (e) {
      throw Exception('Error updating news: $e');
    }
  }

  Future<void> deleteNews(String id) async {
    try {
      await _firestore.collection('news').doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting news: $e');
    }
  }
}
