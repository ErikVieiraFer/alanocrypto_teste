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
import 'package:alanoapp/features/cupula/screens/cupula_coming_soon_screen.dart';
import 'package:alanoapp/services/notification_service.dart';
import 'package:alanoapp/services/alano_post_service.dart';
import 'package:alanoapp/services/signal_service.dart';
import 'package:alanoapp/services/chat_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/welcome_notification_dialog.dart';
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
    const CupulaComingSoonScreen(), // 13 - A Cúpula
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

      // Mostra o diálogo de boas-vindas se for a primeira vez
      WelcomeNotificationDialog.showIfNeeded(context);
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

  Widget _buildFloatingHomeButton() {
    final isSelected = _currentIndex == 0;

    return FloatingActionButton(
      onPressed: () => setState(() => _currentIndex = 0),
      backgroundColor: AppTheme.primaryGreen,
      elevation: isSelected ? 8 : 6,
      child: Icon(
        Icons.home_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
      floatingActionButton: _buildFloatingHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildNavItem(3, Icons.show_chart_rounded, 'Sinais'),
                  _buildNavItem(1, Icons.chat_bubble_rounded, 'Chat'),
                  const SizedBox(width: 60), // Espaço para o botão flutuante
                  _buildNavItem(2, Icons.article_rounded, 'Posts'),
                  _buildNavItem(4, Icons.person_rounded, 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
