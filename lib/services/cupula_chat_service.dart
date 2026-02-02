import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/admin_helper.dart';

class CupulaChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Stream de mensagens (últimas 50, ordenadas por createdAt)
  Stream<QuerySnapshot> getMessages() {
    return _firestore
        .collection('cupula_chat')
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots();
  }

  Future<String?> uploadImage(dynamic imageData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('cupula_chat').child(fileName);

      UploadTask uploadTask;
      if (imageData is Uint8List) {
        uploadTask = ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageData is File) {
        uploadTask = ref.putFile(imageData, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        throw Exception('Tipo de imagem inválido');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  /// Enviar mensagem para o chat (com ou sem imagem, com ou sem reply)
  Future<void> sendMessage({
    required String message,
    String? imageUrl,
    String? audioUrl,
    int? audioDurationSeconds,
    String? videoUrl,
    int? videoDurationSeconds,
    String? replyToId,
    String? replyToUserName,
    String? replyToMessage,
    List<Map<String, dynamic>>? mentions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isBanned = await isUserBanned(user.uid);
    if (isBanned) {
      throw Exception('Você foi bloqueado e não pode enviar mensagens.');
    }

    if (message.trim().isEmpty && imageUrl == null && audioUrl == null && videoUrl == null) return;

    final userData = await getUserData(user.uid);

    await _firestore.collection('cupula_chat').add({
      'userId': user.uid,
      'userName': userData?['displayName'] ?? user.displayName ?? 'Usuário',
      'userPhotoUrl': userData?['photoURL'] ?? user.photoURL,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': userData?['isAdmin'] ?? false,
      'editedAt': null,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'audioDurationSeconds': audioDurationSeconds,
      'videoUrl': videoUrl,
      'videoDurationSeconds': videoDurationSeconds,
      'replyTo': replyToId,
      'replyToUserName': replyToUserName,
      'replyToMessage': replyToMessage,
      'mentions': mentions ?? [],
      'reactions': {},
    });

    if (mentions != null && mentions.isNotEmpty) {
      final senderName = userData?['displayName'] ?? user.displayName ?? 'Usuário';
      for (final mention in mentions) {
        final mentionedUserId = mention['userId'] as String?;
        if (mentionedUserId != null && mentionedUserId != user.uid) {
          await _firestore.collection('notifications').add({
            'userId': mentionedUserId,
            'type': 'cupula_mention',
            'title': 'Você foi mencionado na Cúpula',
            'body': '$senderName mencionou você',
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  /// Editar mensagem (apenas próprias mensagens)
  Future<void> editMessage(String messageId, String newMessage) async {
    final user = _auth.currentUser;
    if (user == null || newMessage.trim().isEmpty) return;

    try {
      final docRef = _firestore.collection('cupula_chat').doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Mensagem não encontrada');
      }

      final data = doc.data();
      final messageUserId = data?['userId'] as String?;

      // Validar se é o dono da mensagem
      if (messageUserId != user.uid) {
        throw Exception('Você só pode editar suas próprias mensagens');
      }

      await docRef.update({
        'message': newMessage.trim(),
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao editar mensagem: $e');
    }
  }

  /// Deletar mensagem (apenas próprias mensagens)
  Future<void> deleteMessage(String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('cupula_chat').doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Mensagem não encontrada');
      }

      final data = doc.data();
      final messageUserId = data?['userId'] as String?;

      // Validar se é o dono da mensagem
      if (messageUserId != user.uid) {
        throw Exception('Você só pode deletar suas próprias mensagens');
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Erro ao deletar mensagem: $e');
    }
  }

  /// Buscar dados do usuário no Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  /// Stream de dados do usuário
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Verificar se usuário é admin (usando AdminHelper)
  bool isUserAdmin(String userId) {
    return AdminHelper.isAdmin(userId);
  }

  /// Obter usuário atual
  User? get currentUser => _auth.currentUser;

  /// Verificar se usuário está logado
  bool get isUserLoggedIn => _auth.currentUser != null;

  // ============================================
  // FUNÇÕES DE MODERAÇÃO (APENAS ADMIN)
  // ============================================

  /// Deletar mensagem de QUALQUER usuário (só admin)
  Future<bool> deleteMessageAsAdmin(String messageId) async {
    if (!AdminHelper.isCurrentUserAdmin()) {
      print('❌ Apenas admin pode deletar mensagens de outros');
      return false;
    }

    try {
      await _firestore.collection('cupula_chat').doc(messageId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar mensagem: $e');
      return false;
    }
  }

  /// Banir usuário (adiciona à lista de banidos)
  Future<bool> banUser(String userId, String userName) async {
    if (!AdminHelper.isCurrentUserAdmin()) {
      print('❌ Apenas admin pode banir usuários');
      return false;
    }

    try {
      await _firestore.collection('banned_users').doc(userId).set({
        'userId': userId,
        'userName': userName,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': _auth.currentUser?.uid,
      });
      return true;
    } catch (e) {
      print('Erro ao banir usuário: $e');
      return false;
    }
  }

  /// Desbanir usuário
  Future<bool> unbanUser(String userId) async {
    if (!AdminHelper.isCurrentUserAdmin()) {
      print('❌ Apenas admin pode desbanir usuários');
      return false;
    }

    try {
      await _firestore.collection('banned_users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Erro ao desbanir usuário: $e');
      return false;
    }
  }

  /// Verificar se usuário está banido
  Future<bool> isUserBanned(String userId) async {
    try {
      final doc = await _firestore.collection('banned_users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getBannedUsers() {
    return _firestore
        .collection('banned_users')
        .orderBy('bannedAt', descending: true)
        .snapshots();
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('cupula_chat').doc(messageId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final reactions = Map<String, List<dynamic>>.from(data['reactions'] ?? {});

    if (reactions[emoji]?.contains(user.uid) ?? false) {
      reactions[emoji]!.remove(user.uid);
      if (reactions[emoji]!.isEmpty) reactions.remove(emoji);
    } else {
      reactions[emoji] = [...(reactions[emoji] ?? []), user.uid];
    }

    await docRef.update({'reactions': reactions});
  }

  Future<List<Map<String, dynamic>>> getMentionableUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isPremium', isEqualTo: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Usuário',
          'photoURL': data['photoURL'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
