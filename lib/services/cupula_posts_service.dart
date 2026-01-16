import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CupulaPostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de posts (últimos 20) - SEM filtro de categoria
  Stream<QuerySnapshot> getPosts() {
    debugPrint('📰 CupulaPostsService.getPosts() chamado');

    return _firestore
        .collection('cupula_posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Erro no stream de posts: $error');
        });
  }

  // Buscar post único por ID
  Future<DocumentSnapshot> getPost(String postId) async {
    return await _firestore.collection('cupula_posts').doc(postId).get();
  }

  // Incrementar views
  Future<void> incrementViews(String postId) async {
    await _firestore.collection('cupula_posts').doc(postId).update({
      'views': FieldValue.increment(1),
    });
  }
}
