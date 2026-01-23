import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LiveChatMessage {
  final String id;
  final String oderId;
  final String oderName;
  final String? oderPhoto;
  final String text;
  final Map<String, List<String>> reactions;
  final DateTime createdAt;

  LiveChatMessage({
    required this.id,
    required this.oderId,
    required this.oderName,
    this.oderPhoto,
    required this.text,
    required this.reactions,
    required this.createdAt,
  });

  factory LiveChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, List<String>> parsedReactions = {};
    if (data['reactions'] != null) {
      final reactionsData = data['reactions'] as Map<String, dynamic>;
      reactionsData.forEach((emoji, userIds) {
        if (userIds is List) {
          parsedReactions[emoji] = List<String>.from(userIds);
        }
      });
    }

    return LiveChatMessage(
      id: doc.id,
      oderId: data['oderId'] ?? '',
      oderName: data['oderName'] ?? 'Usuário',
      oderPhoto: data['oderPhoto'],
      text: data['text'] ?? '',
      reactions: parsedReactions,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  int get totalReactions {
    int total = 0;
    reactions.forEach((_, users) {
      total += users.length;
    });
    return total;
  }

  bool hasReacted(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }
}

class CupulaLiveChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Buscar dados do usuário no Firestore (dados mais atualizados)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  Stream<List<LiveChatMessage>> getMessages(String liveId) {
    debugPrint('💬 CupulaLiveChatService.getMessages() - liveId: $liveId');

    return _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          debugPrint('💬 Messages snapshot: ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) => LiveChatMessage.fromFirestore(doc)).toList();
        })
        .handleError((error) {
          debugPrint('❌ Erro no stream de mensagens: $error');
        });
  }

  Future<void> sendMessage(String liveId, String text) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    if (text.trim().isEmpty) return;

    debugPrint('💬 Enviando mensagem para live $liveId: $text');

    // Buscar dados atualizados do usuário no Firestore
    final userData = await getUserData(user.uid);

    await _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .add({
          'oderId': user.uid,
          'oderName': userData?['displayName'] ?? user.displayName ?? 'Usuário',
          'oderPhoto': userData?['photoURL'] ?? user.photoURL,
          'text': text.trim(),
          'reactions': {},
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> addReaction(String liveId, String messageId, String emoji) async {
    final user = currentUser;
    if (user == null) return;

    debugPrint('😀 Adicionando reação $emoji na mensagem $messageId');

    final docRef = _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .doc(messageId);

    await docRef.update({
      'reactions.$emoji': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> removeReaction(String liveId, String messageId, String emoji) async {
    final user = currentUser;
    if (user == null) return;

    debugPrint('😀 Removendo reação $emoji da mensagem $messageId');

    final docRef = _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .doc(messageId);

    await docRef.update({
      'reactions.$emoji': FieldValue.arrayRemove([user.uid]),
    });
  }

  Future<void> toggleReaction(String liveId, String messageId, String emoji) async {
    final user = currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .doc(messageId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final emojiReactions = reactions[emoji] as List<dynamic>? ?? [];

    if (emojiReactions.contains(user.uid)) {
      await removeReaction(liveId, messageId, emoji);
    } else {
      await addReaction(liveId, messageId, emoji);
    }
  }

  Future<bool> deleteMessage(String liveId, String messageId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final docRef = _firestore
          .collection('cupula_live_chats')
          .doc(liveId)
          .collection('messages')
          .doc(messageId);

      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final oderId = data['oderId'] as String?;

      if (oderId != user.uid) {
        debugPrint('❌ Usuário não tem permissão para deletar esta mensagem');
        return false;
      }

      await docRef.delete();
      debugPrint('🗑️ Mensagem $messageId deletada com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao deletar mensagem: $e');
      return false;
    }
  }

  Stream<int> getViewersCount(String liveId) {
    return _firestore
        .collection('cupula_live_chats')
        .doc(liveId)
        .collection('messages')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ))
        .snapshots()
        .map((snapshot) {
          final uniqueUsers = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final oderId = data['oderId'] as String?;
            if (oderId != null) {
              uniqueUsers.add(oderId);
            }
          }
          return uniqueUsers.length;
        });
  }

  Future<int> cleanTestMessages(String liveId) async {
    try {
      final messagesRef = _firestore
          .collection('cupula_live_chats')
          .doc(liveId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final oderName = (data['oderName'] as String?)?.toLowerCase() ?? '';
        final oderId = (data['oderId'] as String?)?.toLowerCase() ?? '';

        if (oderName == 'teste' || oderId == 'teste') {
          await doc.reference.delete();
          deletedCount++;
          debugPrint('🗑️ Mensagem de teste deletada: ${doc.id}');
        }
      }

      debugPrint('✅ Total de mensagens de teste deletadas: $deletedCount');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Erro ao limpar mensagens de teste: $e');
      return 0;
    }
  }
}
