import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../services/notification_service.dart';
import '../../../services/payment_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'cupula_signals_preview.dart';
import 'cupula_chat_preview.dart';
import 'cupula_posts_preview.dart';
import 'cupula_lives_preview.dart';
import 'cupula_sales_screen.dart';

class CupulaMainScreen extends StatefulWidget {
  const CupulaMainScreen({super.key});

  @override
  State<CupulaMainScreen> createState() => _CupulaMainScreenState();
}

class _CupulaMainScreenState extends State<CupulaMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final NotificationService _notificationService = NotificationService();
  final PaymentService _paymentService = PaymentService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _hasAccess = false;
  bool _isCheckingAccess = true;

  final List<Widget> _screens = const [
    CupulaSignalsPreview(),
    CupulaChatPreview(),
    CupulaPostsPreview(),
    CupulaLivesPreview(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    debugPrint('🏛️ CupulaMainScreen: _checkAccess() iniciado');

    final hasAccess = await _paymentService.hasAccess();
    debugPrint('🏛️ CupulaMainScreen: hasAccess = $hasAccess');

    if (!hasAccess && mounted) {
      debugPrint('🏛️ CupulaMainScreen: ❌ SEM ACESSO - mostrando CupulaSalesScreen');
      setState(() {
        _hasAccess = false;
        _isCheckingAccess = false;
      });
      return;
    }

    if (mounted) {
      debugPrint('🏛️ CupulaMainScreen: ✅ ACESSO LIBERADO - mostrando conteúdo');
      setState(() {
        _hasAccess = hasAccess;
        _isCheckingAccess = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _goBack() {
    // Tenta fazer pop se possível (veio via Navigator.push do drawer)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Se não pode fazer pop (está no IndexedStack), navega para dashboard/home
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 16),
              Text(
                'Verificando acesso...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasAccess) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _goBack(),
          ),
          title: const Text('A Cúpula', style: TextStyle(color: Colors.white)),
        ),
        body: const CupulaSalesScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Alano',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Crypto',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'FX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: _HomeButton(
          onTap: _goBack,
        ),
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
                final displayName = snapshot.data?.get('displayName') as String?;

                return GestureDetector(
                  onTap: _navigateToProfile,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryGreen,
                    backgroundImage: photoURL != null && photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : null,
                    child: photoURL == null || photoURL.isEmpty
                        ? Text(
                            displayName?.isNotEmpty == true
                                ? displayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.show_chart,
                  label: 'Sinais',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.article_outlined,
                  label: 'Posts',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.play_circle_outline,
                  label: 'Lives',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget do botão Home com animação
class _HomeButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HomeButton({required this.onTap});

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              borderRadius: BorderRadius.circular(50),
              child: const Center(
                child: Icon(
                  Icons.home,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
