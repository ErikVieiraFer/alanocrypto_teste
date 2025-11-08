import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../home/screens/comments_screen.dart';
import '../../signals/screens/signals_screen.dart';
import '../../alano_posts/screens/alano_posts_screen.dart';
import '../../home/screens/group_chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.like:
        return Icons.favorite_border;
      case NotificationType.chatReply:
        return Icons.reply;
      case NotificationType.chatReaction:
        return Icons.emoji_emotions_outlined;
      case NotificationType.signal:
        return Icons.show_chart;
      case NotificationType.post:
        return Icons.article_outlined;
      default:
        return Icons.notifications;
    }
  }

  void _navigateToRelatedContent(NotificationType type, String relatedId) {
    switch (type) {
      case NotificationType.comment:
      case NotificationType.like:
        // Navega para a tela de comentários do post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentsScreen(postId: relatedId),
          ),
        );
        break;
      case NotificationType.signal:
        // Navega para a tela de sinais
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SignalsScreen(),
          ),
        );
        break;
      case NotificationType.post:
        // Navega para a tela de posts do Alano
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AlanoPostsScreen(),
          ),
        );
        break;
      case NotificationType.chatReply:
      case NotificationType.chatReaction:
        // Navega para a tela de chat em grupo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GroupChatScreen(),
          ),
        );
        break;
      default:
        // Não faz nada para tipos desconhecidos
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para ver suas notificações.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: () => _notificationService.markAllAsRead(_userId!),
            child: const Text('Marcar todas como lidas'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma notificação ainda', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = !notification.read;

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _notificationService.deleteNotification(notification.id);
                },
                child: ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        _getIconForType(notification.type),
                        color: isUnread ? AppTheme.accentGreen : Colors.grey,
                        size: 32,
                      ),
                    ],
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.content),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(notification.createdAt.toDate(), locale: 'pt_BR'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: isUnread
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    if (isUnread) {
                      _notificationService.markAsRead(notification.id);
                    }
                    _navigateToRelatedContent(notification.type, notification.relatedId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
