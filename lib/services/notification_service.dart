import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');

  static const String _readNotificationsKey = 'read_notifications';

  Stream<List<GlobalNotification>> getGlobalNotifications() {
    return _firestore
        .collection('global_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GlobalNotification.fromFirestore(doc);
      }).toList();
    });
  }

  Future<Set<String>> getReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList(_readNotificationsKey) ?? [];
      return Set<String>.from(readList);
    } catch (e) {
      debugPrint('❌ Erro ao carregar notificações lidas: $e');
      return <String>{};
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList(_readNotificationsKey) ?? [];

      if (!readList.contains(notificationId)) {
        readList.add(notificationId);
        await prefs.setStringList(_readNotificationsKey, readList);
        debugPrint('✅ Notificação marcada como lida: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ Erro ao marcar notificação como lida: $e');
    }
  }

  Future<void> markAllAsRead(List<String> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList(_readNotificationsKey) ?? [];

      for (final id in notificationIds) {
        if (!readList.contains(id)) {
          readList.add(id);
        }
      }

      await prefs.setStringList(_readNotificationsKey, readList);
      debugPrint('✅ ${notificationIds.length} notificações marcadas como lidas');
    } catch (e) {
      debugPrint('❌ Erro ao marcar todas como lidas: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final snapshot = await _firestore
          .collection('global_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final readNotifications = await getReadNotifications();

      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        if (!readNotifications.contains(doc.id)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      debugPrint('❌ Erro ao contar não lidas: $e');
      return 0;
    }
  }

  Future<void> clearAllReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readNotificationsKey);
      debugPrint('✅ Histórico de lidas limpo');
    } catch (e) {
      debugPrint('❌ Erro ao limpar histórico: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS DE COMPATIBILIDADE (notificações individuais)
  // Para menções, comentários, likes, etc.
  // ═══════════════════════════════════════════════════════════

  // Criar uma nova notificação individual
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
      debugPrint('❌ Erro ao criar notificação: $e');
    }
  }

  // Stream para a contagem de notificações não lidas individuais
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Stream para contagem de notificações globais não lidas
  // Combina o stream do Firestore com o SharedPreferences
  Stream<int> getGlobalUnreadCountStream() {
    return _firestore
        .collection('global_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final readNotifications = await getReadNotifications();
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        if (!readNotifications.contains(doc.id)) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }
}

class GlobalNotification {
  final String id;
  final String type;
  final String title;
  final String content;
  final String postId;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final String relatedCollection;

  GlobalNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.postId,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    required this.relatedCollection,
  });

  factory GlobalNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GlobalNotification(
      id: doc.id,
      type: data['type'] ?? 'alano_post',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      postId: data['postId'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedCollection: data['relatedCollection'] ?? 'alano_posts',
    );
  }
}
