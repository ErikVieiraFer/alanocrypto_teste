import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleModel {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> tags;
  final String url;
  final bool isPremium;
  final DateTime publishedAt;

  NewsArticleModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.url,
    required this.isPremium,
    required this.publishedAt,
  });

  factory NewsArticleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsArticleModel(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      url: data['url'] ?? '',
      isPremium: data['isPremium'] ?? false,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'tags': tags,
      'url': url,
      'isPremium': isPremium,
      'publishedAt': Timestamp.fromDate(publishedAt),
    };
  }
}
