import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article_model.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NewsArticleModel>> getNewsStream({int limit = 6}) {
    return _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NewsArticleModel.fromFirestore(doc))
            .toList());
  }

  Future<List<NewsArticleModel>> getNews({int limit = 6}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<List<NewsArticleModel>> getAllNews() async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticleModel.fromFirestore(doc))
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
