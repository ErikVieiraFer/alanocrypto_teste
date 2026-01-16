import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cupula_post_model.dart';

/// Serviço para gerenciar posts premium da Cúpula
class CupulaPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'cupula_posts';

  /// Stream de posts (ordenados por data, mais recentes primeiro)
  Stream<List<CupulaPostModel>> getPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CupulaPostModel.fromFirestore(doc))
            .toList());
  }

  /// Stream de posts por categoria
  Stream<List<CupulaPostModel>> getPostsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CupulaPostModel.fromFirestore(doc))
            .toList());
  }

  /// Buscar post por ID
  Future<CupulaPostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (doc.exists) {
        return CupulaPostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar post: $e');
      return null;
    }
  }

  /// Incrementar visualizações
  Future<void> incrementViews(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erro ao incrementar views: $e');
    }
  }

  /// Criar novo post (apenas admin)
  Future<String?> createPost({
    required String title,
    required String excerpt,
    required String content,
    required String category,
    String? imageUrl,
    required String authorId,
    required String authorName,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _firestore.collection(_collection).add({
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'category': category,
        'imageUrl': imageUrl,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'views': 0,
      });
      return docRef.id;
    } catch (e) {
      print('Erro ao criar post: $e');
      return null;
    }
  }

  /// Atualizar post existente (apenas admin)
  Future<bool> updatePost({
    required String postId,
    String? title,
    String? excerpt,
    String? content,
    String? category,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (excerpt != null) updates['excerpt'] = excerpt;
      if (content != null) updates['content'] = content;
      if (category != null) updates['category'] = category;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;

      await _firestore.collection(_collection).doc(postId).update(updates);
      return true;
    } catch (e) {
      print('Erro ao atualizar post: $e');
      return false;
    }
  }

  /// Deletar post (apenas admin)
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar post: $e');
      return false;
    }
  }

  /// Buscar posts (query de texto)
  Future<List<CupulaPostModel>> searchPosts(String query) async {
    try {
      // Busca simples por título (case-insensitive requer índice composto)
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      final lowercaseQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => CupulaPostModel.fromFirestore(doc))
          .where((post) =>
              post.title.toLowerCase().contains(lowercaseQuery) ||
              post.excerpt.toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      print('Erro ao buscar posts: $e');
      return [];
    }
  }
}
