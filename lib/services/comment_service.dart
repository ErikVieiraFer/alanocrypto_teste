import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Você precisa estar conectado para comentar');
      }

      if (content.trim().isEmpty) {
        throw Exception('Comentário não pode estar vazio');
      }

      final Comment newComment = Comment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userPhotoUrl: user.photoURL ?? '',
        content: content,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('comments').add(newComment.toFirestore());

      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Lógica de notificação
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final postOwnerId = postDoc.data()!['userId'];
        if (user.uid != postOwnerId) {
          await _notificationService.createNotification(
            userId: postOwnerId,
            type: NotificationType.comment,
            title: '${user.displayName ?? 'Alguém'} comentou no seu post',
            content: content,
            relatedId: postId,
          );
        }
      }

      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Erro ao comentar: Permissões insuficientes. Verifique suas configurações',
        );
      } else if (e.code == 'unavailable') {
        throw Exception(
          'Erro ao comentar: Conexão perdida. Verifique sua internet',
        );
      } else if (e.code == 'not-found') {
        throw Exception('Erro ao comentar: Post não encontrado');
      }
      throw Exception('Erro ao comentar: ${e.message}');
    } catch (e) {
      if (e.toString().contains('conectado') ||
          e.toString().contains('vazio')) {
        rethrow;
      }
      throw Exception('Erro ao criar comentário: $e');
    }
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();

      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Erro ao deletar comentário: $e');
      return false;
    }
  }
}
