import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  Future<String?> uploadImage(File? imageFile, Uint8List? imageBytes) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('posts/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // Na web, sempre usar putData com bytes
        final Uint8List data = imageBytes ?? await imageFile!.readAsBytes();
        uploadTask = ref.putData(data);
      } else {
        // No mobile, usar putFile
        if (imageFile != null) {
          uploadTask = ref.putFile(imageFile);
        } else {
          return null;
        }
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<bool> createPost({
    required String content,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      String? imageUrl;
      if (imageFile != null || imageBytes != null) {
        imageUrl = await uploadImage(imageFile, imageBytes);
      }

      final Post newPost = Post(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userPhotoUrl: user.photoURL ?? '',
        content: content,
        imageUrl: imageUrl,
        likedBy: [],
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      final postDocRef = await _firestore
          .collection('posts')
          .add(newPost.toFirestore());

      // Fan-out Notification Logic - Notificar todos os usuários sobre o novo post
      final usersSnapshot = await _firestore.collection('users').get();
      if (usersSnapshot.docs.isEmpty) {
        return true; // No users to notify
      }

      final batch = _firestore.batch();
      final notificationsCollection = _firestore.collection('notifications');

      // Truncar o conteúdo para a notificação
      final contentPreview = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;

      for (final userDoc in usersSnapshot.docs) {
        // Não notificar o próprio autor do post
        if (userDoc.id == user.uid) continue;

        final newNotifRef = notificationsCollection.doc();
        batch.set(newNotifRef, {
          'userId': userDoc.id,
          'type': NotificationType.post.name,
          'title': 'Novo post de ${user.displayName ?? 'Alano Cripto'}!',
          'content': contentPreview,
          'read': false,
          'relatedId': postDocRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return true;
    } catch (e) {
      print('Erro ao criar post: $e');
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Você precisa estar conectado para curtir');
      }

      final DocumentReference postRef = _firestore
          .collection('posts')
          .doc(postId);
      final DocumentSnapshot postDoc = await postRef.get();

      if (!postDoc.exists) {
        throw Exception('Post não encontrado');
      }

      final Post post = Post.fromFirestore(postDoc);
      final List<String> likedBy = List.from(post.likedBy);

      final bool isLiking = !likedBy.contains(user.uid);

      if (isLiking) {
        likedBy.add(user.uid);
        if (user.uid != post.userId) {
          await _notificationService.createNotification(
            userId: post.userId,
            type: NotificationType.like,
            title: '${user.displayName ?? 'Alguém'} curtiu seu post',
            content: post.content.length > 50
                ? '${post.content.substring(0, 50)}...'
                : post.content,
            relatedId: postId,
          );
        }
      } else {
        likedBy.remove(user.uid);
      }

      await postRef.update({'likedBy': likedBy});
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Erro ao curtir: Permissões insuficientes. Verifique suas configurações',
        );
      } else if (e.code == 'unavailable') {
        throw Exception(
          'Erro ao curtir: Conexão perdida. Verifique sua internet',
        );
      }
      throw Exception('Erro ao curtir: ${e.message}');
    } catch (e) {
      if (e.toString().contains('conectado') ||
          e.toString().contains('encontrado')) {
        rethrow;
      }
      throw Exception('Erro ao curtir post: $e');
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        final Post post = Post.fromFirestore(postDoc);

        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          try {
            final Reference imageRef = _storage.refFromURL(post.imageUrl!);
            await imageRef.delete();
          } catch (e) {
            print('Erro ao deletar imagem do storage: $e');
          }
        }
      }

      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar post: $e');
      return false;
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': content,
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar post: $e');
      return false;
    }
  }
}
