import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  comment,
  like,
  signal,
  post,
  mention,
  chatReply,
  chatReaction, // Adicionado para reações no chat
  unknown,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool read;
  final String relatedId;
  final Timestamp createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.read,
    required this.relatedId,
    required this.createdAt,
  });

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'comment':
        return NotificationType.comment;
      case 'like':
        return NotificationType.like;
      case 'signal':
        return NotificationType.signal;
      case 'post':
        return NotificationType.post;
      case 'mention':
        return NotificationType.mention;
      case 'chatReply':
        return NotificationType.chatReply;
      case 'chatReaction':
        return NotificationType.chatReaction;
      default:
        return NotificationType.unknown;
    }
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _typeFromString(data['type'] ?? 'unknown'),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      read: data['read'] ?? false,
      relatedId: data['relatedId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'content': content,
      'read': read,
      'relatedId': relatedId,
      'createdAt': createdAt,
    };
  }
}
