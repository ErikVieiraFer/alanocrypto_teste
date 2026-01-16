import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Upload de imagem para o chat
  Future<String?> uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('cupula_chat').child(fileName);

      final uploadTask = ref.putFile(imageFile);
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
    String? replyToId,
    String? replyToUserName,
    String? replyToMessage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // VERIFICAR SE ESTÁ BANIDO
    final isBanned = await isUserBanned(user.uid);
    if (isBanned) {
      throw Exception('Você foi bloqueado e não pode enviar mensagens.');
    }

    if (message.trim().isEmpty && imageUrl == null) return;

    // Buscar dados completos do usuário no Firestore
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
      'replyTo': replyToId,
      'replyToUserName': replyToUserName,
      'replyToMessage': replyToMessage,
    });
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

  /// Listar usuários banidos (só admin)
  Stream<QuerySnapshot> getBannedUsers() {
    return _firestore
        .collection('banned_users')
        .orderBy('bannedAt', descending: true)
        .snapshots();
  }
}
