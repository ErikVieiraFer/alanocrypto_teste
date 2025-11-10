import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alano_post_model.dart';
import '../models/notification_model.dart';

class AlanoPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AlanoPost>> getAlanoPosts() {
    return _firestore
        .collection('alano_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AlanoPost.fromFirestore(doc)).toList();
    });
  }

  Future<void> toggleLike(String postId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final DocumentReference postRef = _firestore.collection('alano_posts').doc(postId);
      final DocumentSnapshot postDoc = await postRef.get();

      if (!postDoc.exists) return;

      final AlanoPost post = AlanoPost.fromFirestore(postDoc);
      final List<String> likedBy = List.from(post.likedBy);

      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
      } else {
        likedBy.add(user.uid);
      }

      await postRef.update({'likedBy': likedBy});
    } catch (e) {
      print('Erro ao dar like: $e');
    }
  }

  Future<void> incrementViews(String postId) async {
    try {
      await _firestore.collection('alano_posts').doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erro ao incrementar views: $e');
    }
  }


  Future<bool> createPost({
    required String title,
    required String content,
    String? videoUrl,
    String? imageUrl,
    String? thumbnailUrl,
  }) async {
    try {
      final newPost = AlanoPost(
        id: '',
        title: title,
        content: content,
        videoUrl: videoUrl,
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        likedBy: [],
        viewedBy: [],
        views: 0,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('alano_posts').add(newPost.toFirestore());
      await _createNotificationsForAllUsers(docRef.id, title);
      return true;
    } catch (e) {
      print('Erro ao criar post: $e');
      return false;
    }
  }

  Future<void> _createNotificationsForAllUsers(String postId, String title) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      if (usersSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      final notificationsCollection = _firestore.collection('notifications');

      for (final userDoc in usersSnapshot.docs) {
        final newNotifRef = notificationsCollection.doc();
        batch.set(newNotifRef, {
          'userId': userDoc.id,
          'type': NotificationType.post.name,
          'title': 'Novo Post do Alano',
          'content': title,
          'read': false,
          'relatedId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao criar notificações: $e');
    }
  }
}