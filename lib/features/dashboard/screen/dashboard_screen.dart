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
import 'package:alanoapp/features/economic_calendar/screens/economic_calendar_screen.dart';
// import 'package:alanoapp/features/economic_calendar/screens/economic_calendar_coming_soon_screen.dart'; // DESABILITADO - Funcionalidade implementada
import 'package:alanoapp/features/management/screens/management_screen.dart';
import 'package:alanoapp/services/notification_service.dart';
import 'package:alanoapp/services/fcm_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/welcome_notification_dialog.dart';
import '../../../widgets/install_pwa_dialog.dart';
import '../../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

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
  bool _isDrawerOpen = false;
  bool _isDialogOpen = false;

  final NotificationService _notificationService = NotificationService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  final Set<int> _loadedScreens = {};

  // Chaves para SharedPreferences (última visualização)
  static const String _keyLastPostView = 'last_post_view';
  static const String _keyLastSignalView = 'last_signal_view';

  // Chaves para SharedPreferences (última visualização)
  //   static const String _keyLastPostView = 'last_post_view';
  //   static const String _keyLastSignalView = 'last_signal_view';


  Widget _buildScreen(int index) {
    if (!_loadedScreens.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return HomeScreen(isDrawerOpen: _isDrawerOpen, isDialogOpen: _isDialogOpen);
      case 1:
        return const GroupChatScreen();
      case 2:
        return const AlanoPostsScreen();
      case 3:
        return const SignalsScreen();
      case 4:
        return const ProfileScreen();
      case 5:
        return const MarketsScreen();
      case 6:
        return const WatchlistScreen();
      case 7:
        return const ForexCalculatorScreen();
      case 8:
        return const CoursesScreen();
      case 9:
        return const PortfolioScreen();
      case 10:
        return const AIChatScreen();
      case 11:
        return const UsefulLinksScreen();
      case 12:
        return const SupportScreen();
      case 13:
        return const CupulaComingSoonScreen();
      case 14:
        return const EconomicCalendarScreen();
      case 15:
        return const ManagementScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> get _screens => List.generate(16, (index) => _buildScreen(index));
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

    _currentIndex = widget.initialIndex;
    _loadedScreens.add(_currentIndex);

    _setupFcmNavigationCallback();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialTab'] != null) {
        final int initialTab = args['initialTab'] as int;
        if (initialTab >= 0 && initialTab < 16) {
          setState(() {
            _currentIndex = initialTab;
            _loadedScreens.add(initialTab);
          });
        }
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showFirstTimeDialogs(context);
        }
      });
    });
  }

  void _setupFcmNavigationCallback() {
    final fcmService = FcmService();
    fcmService.setNavigationCallback((int screenIndex) {
      if (mounted && screenIndex >= 0 && screenIndex < 16) {
        setState(() {
          _currentIndex = screenIndex;
          _loadedScreens.add(screenIndex);
        });
      }
    });
  }

  Future<void> _showFirstTimeDialogs(BuildContext context) async {
    setState(() => _isDialogOpen = true);

    await WelcomeNotificationDialog.showIfNeeded(context);

    if (context.mounted) {
      await InstallPwaDialog.showIfNeeded(context);
    }

    if (mounted) {
      setState(() => _isDialogOpen = false);
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
    if (index >= 0 && index < 16) {
      setState(() {
        _currentIndex = index;
        _loadedScreens.add(index);
      });
    }
  }

  Widget _buildHomeButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _currentIndex = 0;
          _loadedScreens.add(0);
        }),
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
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Icon(
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
        onTap: () => setState(() {
          _currentIndex = index;
          _loadedScreens.add(index);
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
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

  Widget _buildNavItemWithBadge(int index, IconData icon, String label, Stream<int> badgeStream) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
            _loadedScreens.add(index);
          });
          if (index == 1) _resetChatBadge();
          if (index == 2) _saveLastPostView();
          if (index == 3) _saveLastSignalView();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    size: 22,
                  ),
                  StreamBuilder<int>(
                    stream: badgeStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0 || isSelected) return const SizedBox.shrink();
                      return Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

  Stream<int> _getChatBadgeStream() {
    if (_userId == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) => (doc.data()?['chatNotificationCount'] ?? 0) as int)
        .debounceTime(const Duration(milliseconds: 300))
        .distinct();
  }

  Stream<int> _getPostsBadgeStream() {
    return FirebaseFirestore.instance
        .collection('alano_posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      final lastView = prefs.getInt(_keyLastPostView) ?? 0;
      final lastViewDate = DateTime.fromMillisecondsSinceEpoch(lastView);
      int count = 0;
      for (final doc in snapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isAfter(lastViewDate)) {
          count++;
        }
      }
      return count;
    })
        .debounceTime(const Duration(milliseconds: 300))
        .distinct();
  }

  Stream<int> _getSignalsBadgeStream() {
    return FirebaseFirestore.instance
        .collection('signals')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      final lastView = prefs.getInt(_keyLastSignalView) ?? 0;
      final lastViewDate = DateTime.fromMillisecondsSinceEpoch(lastView);
      int count = 0;
      for (final doc in snapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isAfter(lastViewDate)) {
          count++;
        }
      }
      return count;
    })
        .debounceTime(const Duration(milliseconds: 300))
        .distinct();
  }

  Future<void> _resetChatBadge() async {
    if (_userId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({'chatNotificationCount': 0});
    } catch (e) {
      debugPrint('Erro ao resetar badge do chat: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpened) {
        setState(() => _isDrawerOpen = isOpened);
      },
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
          StreamBuilder<int>(
            stream: _notificationService.getGlobalUnreadCountStream(),
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
                        decoration: const BoxDecoration(
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
              color: Colors.black.withValues(alpha: 0.3),
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
                _buildNavItemWithBadge(3, Icons.show_chart_rounded, 'Sinais', _getSignalsBadgeStream()),
                _buildNavItemWithBadge(1, Icons.chat_bubble_rounded, 'Chat', _getChatBadgeStream()),
                _buildHomeButton(),
                _buildNavItemWithBadge(2, Icons.article_rounded, 'Posts', _getPostsBadgeStream()),
                _buildNavItem(4, Icons.person_rounded, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
