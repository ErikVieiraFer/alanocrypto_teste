import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/screen/dashboard_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  Set<String> _readNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadReadNotifications();
  }

  Future<void> _loadReadNotifications() async {
    final readNotifs = await _notificationService.getReadNotifications();
    if (mounted) {
      setState(() {
        _readNotifications = readNotifs;
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'agora';
    }
  }

  /// Retorna o índice da tab no Dashboard baseado no tipo de notificação
  /// Índices do Dashboard:
  /// 0: Home, 1: Chat, 2: Posts, 3: Sinais, 4: Perfil, 5: Mercados,
  /// 6: Watchlist, 7: Calculadora, 8: Cursos, 9: Portfólio, 10: IA,
  /// 11: Links, 12: Suporte, 13: Cúpula, 14: Calendário, 15: Gerenciamento
  int _getIndexForNotificationType(String type) {
    switch (type) {
      case 'new_post':
      case 'post':
      case 'alano_post':
        return 2; // AlanoPostsScreen
      case 'new_signal':
      case 'signal':
        return 3; // SignalsScreen
      case 'new_course':
      case 'course':
        return 8; // CoursesScreen
      case 'chat_message':
      case 'chat':
      case 'mention':
        return 1; // GroupChatScreen
      case 'news':
        return 0; // HomeScreen (notícias aparecem na home)
      default:
        return 2; // Default: Posts do Alano
    }
  }

  /// Navega para a tela de destino mantendo AppBar e BottomNavBar
  void _navigateToDestination(BuildContext context, String notificationType) {
    // Tenta encontrar o DashboardScreenState no contexto
    final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();

    if (dashboardState != null) {
      // Muda a tab no Dashboard
      final targetIndex = _getIndexForNotificationType(notificationType);
      dashboardState.changeTab(targetIndex);

      // Fecha a tela de notificações para voltar ao Dashboard
      Navigator.pop(context);
    } else {
      // Fallback: navega para Dashboard com índice específico
      final targetIndex = _getIndexForNotificationType(notificationType);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(initialIndex: targetIndex),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como lidas',
            onPressed: () async {
              // Marcar todas como lidas
              final snapshot = await FirebaseFirestore.instance
                  .collection('global_notifications')
                  .limit(50)
                  .get();

              final ids = snapshot.docs.map((doc) => doc.id).toList();
              await _notificationService.markAllAsRead(ids);

              if (mounted) {
                setState(() {
                  _readNotifications.addAll(ids);
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<GlobalNotification>>(
        stream: _notificationService.getGlobalNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação ainda',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = _readNotifications.contains(notif.id);

              return ListTile(
                leading: Icon(
                  Icons.article,
                  color: isRead ? Colors.grey : AppTheme.accentGreen,
                  size: 32,
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.grey : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.content,
                      style: TextStyle(
                        color: isRead ? Colors.grey[600] : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notif.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: !isRead
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () async {
                  // Marcar como lida
                  await _notificationService.markAsRead(notif.id);
                  if (!mounted) return;

                  setState(() {
                    _readNotifications.add(notif.id);
                  });

                  // Navegar para a tela correta mantendo AppBar e BottomNavBar
                  _navigateToDestination(context, notif.type);
                },
              );
            },
          );
        },
      ),
    );
  }
}
