import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para posts premium da Cúpula
class CupulaPostModel {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String category; // Estratégia, Análise, Educação
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int views;

  CupulaPostModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
  });

  factory CupulaPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CupulaPostModel(
      id: doc.id,
      title: data['title'] ?? '',
      excerpt: data['excerpt'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'Educação',
      imageUrl: data['imageUrl'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Alano',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: data['views'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'views': views,
    };
  }

  CupulaPostModel copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? content,
    String? category,
    String? imageUrl,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? views,
  }) {
    return CupulaPostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
    );
  }

  /// Retorna o emoji correspondente à categoria
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'estratégia':
        return '📈';
      case 'análise':
        return '💹';
      case 'educação':
        return '📚';
      default:
        return '📰';
    }
  }

  /// Retorna a cor correspondente à categoria
  static String getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'estratégia':
        return 'green';
      case 'análise':
        return 'blue';
      case 'educação':
        return 'purple';
      default:
        return 'green';
    }
  }
}
