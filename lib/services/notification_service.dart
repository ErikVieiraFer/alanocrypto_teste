import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final CollectionReference _notificationsCollection = FirebaseFirestore
      .instance
      .collection('notifications');

  // Stream de notificações para um usuário específico
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Marcar uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({'read': true});
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
    }
  }

  // Marcar todas as notificações de um usuário como lidas
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Erro ao marcar todas as notificações como lidas: $e');
    }
  }

  // Deletar uma notificação
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Erro ao deletar notificação: $e');
    }
  }

  // Criar uma nova notificação
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String content,
    required String relatedId,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'content': content,
        'read': false,
        'relatedId': relatedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao criar notificação: $e');
    }
  }

  // Stream para a contagem de notificações não lidas
  Stream<int> getUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
