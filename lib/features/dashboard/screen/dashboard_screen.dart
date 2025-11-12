import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alanoapp/features/home/screens/home_screen.dart';
import 'package:alanoapp/features/home/screens/group_chat_screen.dart';
import 'package:alanoapp/features/profile/screens/profile_screen.dart';
import 'package:alanoapp/features/alano_posts/screens/alano_posts_screen.dart';
import 'package:alanoapp/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:alanoapp/features/signals/screens/signals_screen.dart';
import 'package:alanoapp/features/notifications/screens/notifications_screen.dart';
import 'package:alanoapp/features/crypto/screens/market_screen.dart';
import 'package:alanoapp/features/crypto/screens/watchlist_screen.dart';
import 'package:alanoapp/features/forex/screens/forex_calculator_screen.dart';
import 'package:alanoapp/features/courses/screens/courses_screen.dart';
import 'package:alanoapp/features/portfolio/screens/portfolio_screen.dart';
import 'package:alanoapp/features/links/screens/useful_links_screen.dart';
import 'package:alanoapp/features/support/screens/support_screen.dart';
import 'package:alanoapp/services/notification_service.dart';
import 'package:alanoapp/services/alano_post_service.dart';
import 'package:alanoapp/services/signal_service.dart';
import 'package:alanoapp/services/chat_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_logo.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final NotificationService _notificationService = NotificationService();
  final AlanoPostService _alanoPostService = AlanoPostService();
  final SignalService _signalService = SignalService();
  final ChatService _chatService = ChatService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _screens = [
    const HomeScreen(), // 0 - Home (Dashboard)
    const GroupChatScreen(), // 1 - Comunidade
    const AlanoPostsScreen(), // 2 - Posts
    const SignalsScreen(), // 3 - Sinais
    const ProfileScreen(), // 4 - Perfil
    const MarketScreen(), // 5 - Mercado
    const WatchlistScreen(), // 6 - Watchlist
    const ForexCalculatorScreen(), // 7 - Calculadora Forex
    const CoursesScreen(), // 8 - Cursos
    const PortfolioScreen(), // 9 - Portfólio
    const AIChatScreen(), // 10 - Alano IA
    const UsefulLinksScreen(), // 11 - Links Úteis
    const SupportScreen(), // 12 - Suporte
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialTab'] != null) {
        final int initialTab = args['initialTab'] as int;
        // Garantir que o índice está dentro do range
        if (initialTab >= 0 && initialTab < _screens.length) {
          setState(() {
            _currentIndex = initialTab;
          });
        }
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  // Método público para mudar tabs (usado pelo AppDrawer)
  void changeTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Retorna o título baseado na tela atual
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'AlanoCryptoFX';
      case 1:
        return 'Comunidade';
      case 2:
        return 'Posts do Alano';
      case 3:
        return 'Sinais';
      case 4:
        return 'Perfil';
      case 5:
        return 'Mercado';
      case 6:
        return 'Watchlist';
      case 7:
        return 'Calculadora Forex';
      case 8:
        return 'Cursos';
      case 9:
        return 'Portfólio';
      case 10:
        return 'Alano IA';
      case 11:
        return 'Links Úteis';
      case 12:
        return 'Suporte';
      default:
        return 'AlanoCryptoFX';
    }
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
        title: _currentIndex == 0
            ? const AppLogo(fontSize: 20)
            : Text(
                _getTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                            border: Border.all(
                              color: AppTheme.appBarColor,
                              width: 2,
                            ),
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
                      _currentIndex = 4; // Perfil
                    });
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentGreen,
                    backgroundImage: photoURL != null && photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : null,
                    child: photoURL == null || photoURL.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex <= 4 ? _currentIndex : 0,
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Comunidade',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Sinais',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
