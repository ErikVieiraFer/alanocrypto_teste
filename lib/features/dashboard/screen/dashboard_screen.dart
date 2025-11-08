import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alanoapp/features/home/screens/group_chat_screen.dart';
import 'package:alanoapp/features/profile/screens/profile_screen.dart';
import 'package:alanoapp/features/alano_posts/screens/alano_posts_screen.dart';
import 'package:alanoapp/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:alanoapp/features/signals/screens/signals_screen.dart';
import 'package:alanoapp/features/notifications/screens/notifications_screen.dart';
import 'package:alanoapp/services/notification_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_logo.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final NotificationService _notificationService = NotificationService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _screens = [
    const GroupChatScreen(),       // 0 - Comunidade
    const ProfileScreen(),          // 1 - Perfil
    const AlanoPostsScreen(),       // 2 - Posts
    const AIChatScreen(),           // 3 - IA
    const SignalsScreen(),          // 4 - Sinais
    const NotificationsScreen(),    // 5 - Notificações
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialTab'] != null) {
        setState(() {
          _currentIndex = args['initialTab'] as int;
        });
      }
    });
  }

  void _navigateToNotifications() {
    setState(() {
      _currentIndex = 5; // Índice da tela de notificações
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const AppLogo(fontSize: 20),
        actions: [
          if (_userId != null)
            StreamBuilder<int>(
              stream: _notificationService.getUnreadCount(_userId!),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.accentGreen,
                      ),
                      onPressed: _navigateToNotifications,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.appBarColor, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .snapshots(),
              builder: (context, snapshot) {
                final photoURL = snapshot.data?.get('photoURL') as String?;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1; // Perfil
                    });
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentGreen,
                    backgroundImage: photoURL != null && photoURL.isNotEmpty
                      ? NetworkImage(photoURL)
                      : null,
                    child: photoURL == null || photoURL.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.backgroundColor,
        selectedItemColor: AppTheme.accentGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Comunidade',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.android),
            label: 'IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Sinais',
          ),
        ],
      ),
    );
  }
}