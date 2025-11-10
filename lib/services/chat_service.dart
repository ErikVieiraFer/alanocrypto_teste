import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/message_model.dart';
import '../features/home/widgets/message_input.dart' show PickedImageFile;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _messagesCollection = 'chat_messages';
  static const int _messagesLimit = 50;

  // Enviar mensagem
  Future<void> sendMessage({
    required String text,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? imageUrl,
    String? replyToId,
    String? replyToText,
    String? replyToUserName,
  }) async {
    try {
      final docRef = _firestore.collection(_messagesCollection).doc();

      final message = Message(
        id: docRef.id,
        text: text,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToUserName: replyToUserName,
      );

      await docRef.set(message.toJson());
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  // Upload de imagem (suporta Web e Mobile)
  Future<String> uploadMessageImage(PickedImageFile imageFile, String userId) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final Reference ref = _storage.ref().child('chat_images').child(fileName);

      UploadTask uploadTask;

      if (kIsWeb && imageFile.bytes != null) {
        // For web: use putData with bytes
        uploadTask = ref.putData(
          imageFile.bytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (imageFile.file != null) {
        // For mobile: use putFile
        uploadTask = ref.putFile(imageFile.file!);
      } else {
        throw Exception('Nenhuma imagem válida fornecida');
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  // Obter mensagens (stream)
  Stream<List<Message>> getMessages() {
    return _firestore
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(_messagesLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    });
  }

  // Adicionar reação
  Future<void> addReaction(String messageId, String emoji, String userId) async {
    try {
      final docRef = _firestore.collection(_messagesCollection).doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final message = Message.fromJson(doc.data()!);
      final reactions = Map<String, List<String>>.from(message.reactions);

      // Remove reação anterior do usuário em outros emojis
      reactions.forEach((key, value) {
        value.remove(userId);
      });

      // Adiciona nova reação
      if (!reactions.containsKey(emoji)) {
        reactions[emoji] = [];
      }
      reactions[emoji]!.add(userId);

      // Remove emojis vazios
      reactions.removeWhere((key, value) => value.isEmpty);

      await docRef.update({'reactions': reactions});
    } catch (e) {
      throw Exception('Erro ao adicionar reação: $e');
    }
  }

  // Remover reação
  Future<void> removeReaction(String messageId, String emoji, String userId) async {
    try {
      final docRef = _firestore.collection(_messagesCollection).doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final message = Message.fromJson(doc.data()!);
      final reactions = Map<String, List<String>>.from(message.reactions);

      if (reactions.containsKey(emoji)) {
        reactions[emoji]!.remove(userId);
        if (reactions[emoji]!.isEmpty) {
          reactions.remove(emoji);
        }
      }

      await docRef.update({'reactions': reactions});
    } catch (e) {
      throw Exception('Erro ao remover reação: $e');
    }
  }

  // Deletar mensagem (apenas próprio usuário)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final docRef = _firestore.collection(_messagesCollection).doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final message = Message.fromJson(doc.data()!);

      if (message.userId != userId) {
        throw Exception('Você só pode deletar suas próprias mensagens');
      }

      // Deletar imagem se existir
      if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(message.imageUrl!);
          await ref.delete();
        } catch (e) {
          // Ignorar erro de deleção de imagem
        }
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Erro ao deletar mensagem: $e');
    }
  }

  // Editar mensagem
  Future<void> editMessage(String messageId, String newText, String userId) async {
    try {
      final docRef = _firestore.collection(_messagesCollection).doc(messageId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final message = Message.fromJson(doc.data()!);

      if (message.userId != userId) {
        throw Exception('Você só pode editar suas próprias mensagens');
      }

      await docRef.update({
        'text': newText,
        'isEdited': true,
      });
    } catch (e) {
      throw Exception('Erro ao editar mensagem: $e');
    }
  }

  // Obter mensagem por ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final doc = await _firestore.collection(_messagesCollection).doc(messageId).get();

      if (!doc.exists) return null;

      return Message.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

}
