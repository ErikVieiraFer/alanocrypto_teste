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
import 'package:alanoapp/features/markets/screens/markets_screen.dart';
import 'package:alanoapp/features/forex/screens/forex_calculator_screen.dart';
import 'package:alanoapp/features/courses/screens/courses_screen.dart';
import 'package:alanoapp/features/portfolio/screens/portfolio_screen.dart';
import 'package:alanoapp/features/links/screens/useful_links_screen.dart';
import 'package:alanoapp/features/support/screens/support_screen.dart';
import 'package:alanoapp/features/cupula/screens/cupula_coming_soon_screen.dart';
// import 'package:alanoapp/features/economic_calendar/screens/economic_calendar_screen.dart'; // DESABILITADO - Em desenvolvimento
import 'package:alanoapp/features/economic_calendar/screens/economic_calendar_coming_soon_screen.dart';
import 'package:alanoapp/features/management/screens/management_screen.dart';
import 'package:alanoapp/services/notification_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/welcome_notification_dialog.dart';
import '../../../widgets/install_pwa_dialog.dart';
import '../../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  final NotificationService _notificationService = NotificationService();
  //   final AlanoPostService _alanoPostService = AlanoPostService();
  //   final SignalService _signalService = SignalService();
  //   final ChatService _chatService = ChatService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // Chaves para SharedPreferences (última visualização)
  static const String _keyLastPostView = 'last_post_view';
  static const String _keyLastSignalView = 'last_signal_view';

  // Chaves para SharedPreferences (última visualização)
  //   static const String _keyLastPostView = 'last_post_view';
  //   static const String _keyLastSignalView = 'last_signal_view';


  final List<Widget> _screens = [
    const HomeScreen(), // 0 - Home (Dashboard)
    const GroupChatScreen(), // 1 - Comunidade
    const AlanoPostsScreen(), // 2 - Posts
    const SignalsScreen(), // 3 - Sinais
    const ProfileScreen(), // 4 - Perfil
    const MarketsScreen(), // 5 - Mercados (Novo com integração CoinGecko)
    const WatchlistScreen(), // 6 - Watchlist
    const ForexCalculatorScreen(), // 7 - Calculadora Forex
    const CoursesScreen(), // 8 - Cursos
    const PortfolioScreen(), // 9 - Portfólio
    const AIChatScreen(), // 10 - Alano IA
    const UsefulLinksScreen(), // 11 - Links Úteis
    const SupportScreen(), // 12 - Suporte
    const CupulaComingSoonScreen(), // 13 - A Cúpula
    const EconomicCalendarComingSoonScreen(), // 14 - Calendário Econômico (Em Breve)
    const ManagementScreen(), // 15 - Gerenciamento
  ];
  // ═══════════════════════════════════════════════════════════
  // MÉTODOS DE GERENCIAMENTO DE ÚLTIMA VISUALIZAÇÃO
  // ═══════════════════════════════════════════════════════════

  /// Salva timestamp da última visualização de posts
  Future<void> _saveLastPostView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPostView, DateTime.now().millisecondsSinceEpoch);
  }

  /// Salva timestamp da última visualização de sinais
  Future<void> _saveLastSignalView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSignalView, DateTime.now().millisecondsSinceEpoch);
  }

  /// Retorna timestamp da última visualização de posts
  Future<DateTime?> _getLastPostView() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastPostView);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Retorna timestamp da última visualização de sinais
  Future<DateTime?> _getLastSignalView() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastSignalView);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // ═══════════════════════════════════════════════════════════
  // STREAMS PARA DETECTAR NOVOS CONTEÚDOS
  // ═══════════════════════════════════════════════════════════

  /// Stream que verifica se há novos posts
  Stream<bool> _hasNewPosts() async* {
    final lastView = await _getLastPostView();
    
    yield* FirebaseFirestore.instance
        .collection('alano_posts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return false;
      if (lastView == null) return true;

      final latestPost = snapshot.docs.first.data();
      final postTimestamp = (latestPost['createdAt'] as Timestamp?)?.toDate();

      return postTimestamp != null && postTimestamp.isAfter(lastView);
    });
  }

  /// Stream que verifica se há novos sinais
  Stream<bool> _hasNewSignals() async* {
    final lastView = await _getLastSignalView();
    
    yield* FirebaseFirestore.instance
        .collection('signals')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return false;
      if (lastView == null) return true;

      final latestSignal = snapshot.docs.first.data();
      final signalTimestamp = (latestSignal['createdAt'] as Timestamp?)?.toDate();

      return signalTimestamp != null && signalTimestamp.isAfter(lastView);
    });
  }

  /// Stream que verifica se há mensagens no chat
  Stream<bool> _hasUnreadChat() {
    if (_userId == null) return Stream.value(false);
    
    return FirebaseFirestore.instance
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }



  @override
  void initState() {
    super.initState();

    // Inicializar com o índice fornecido
    _currentIndex = widget.initialIndex;

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

      // Mostra os diálogos de primeira vez em sequência
      _showFirstTimeDialogs(context);
    });
  }

  Future<void> _showFirstTimeDialogs(BuildContext context) async {
    // Primeiro mostra o diálogo de boas-vindas/notificações
    await WelcomeNotificationDialog.showIfNeeded(context);

    // Depois mostra o diálogo de instalação PWA
    if (context.mounted) {
      await InstallPwaDialog.showIfNeeded(context);
    }
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

  Widget _buildHomeButton() {
    final isSelected = _currentIndex == 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
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
                      // Toggle entre Perfil (index 4) e Home (index 0)
                      if (_currentIndex == 4) {
                        _currentIndex = 0; // Se já está no perfil, vai pra Home
                      } else {
                        _currentIndex = 4; // Se não está no perfil, vai pro Perfil
                      }
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
      bottomNavigationBar: Container(
        height: 70,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(3, Icons.show_chart_rounded, 'Sinais'),
                _buildNavItem(1, Icons.chat_bubble_rounded, 'Chat'),
                _buildHomeButton(), // Botão Home no centro
                _buildNavItem(2, Icons.article_rounded, 'Posts'),
                _buildNavItem(4, Icons.person_rounded, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
