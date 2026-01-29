import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alanoapp/theme/app_theme.dart';
import '../features/dashboard/screen/dashboard_screen.dart';
import '../services/payment_service.dart';
import '../features/cupula/screens/cupula_sales_screen.dart';
import '../features/cupula/screens/cupula_main_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final PaymentService _paymentService = PaymentService();
  bool _isCheckingAccess = false;

  Future<void> _handleCupulaTap(BuildContext context) async {
    if (_isCheckingAccess) return;

    debugPrint('🏛️ Drawer: Navegando para Cúpula...');
    setState(() => _isCheckingAccess = true);

    try {
      final hasAccess = await _paymentService.hasAccess();
      debugPrint('🏛️ Drawer: hasAccess = $hasAccess');

      if (!mounted) return;

      Navigator.pop(context);

      if (!mounted) return;

      if (hasAccess) {
        debugPrint('🏛️ Drawer: Usuário tem acesso, abrindo CupulaMainScreen (fullscreen)');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CupulaMainScreen(),
            fullscreenDialog: true,
          ),
        );
      } else {
        debugPrint('🏛️ Drawer: Usuário não tem acesso, abrindo CupulaSalesScreen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (routeContext) => Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                backgroundColor: AppTheme.appBarColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(routeContext),
                ),
                title: const Text('A Cúpula', style: TextStyle(color: Colors.white)),
              ),
              body: const CupulaSalesScreen(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingAccess = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor.withValues(alpha:0.98),
              AppTheme.cardDark.withValues(alpha:0.98),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSection('Principal', [
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        onTap: () => _changeTab(context, 0),
                      ),
                      _buildDrawerItem(
                        icon: Icons.trending_up_rounded,
                        title: 'Mercado',
                        onTap: () => _changeTab(context, 5),
                      ),
                      _buildDrawerItem(
                        icon: Icons.star_rounded,
                        title: 'Watchlist',
                        onTap: () => _changeTab(context, 6),
                      ),
                    ]),

                    _buildSection('Comunidade', [
                      _buildDrawerItem(
                        icon: Icons.people_rounded,
                        title: 'Comunidade',
                        onTap: () => _changeTab(context, 1),
                      ),
                      _buildDrawerItem(
                        icon: Icons.article_rounded,
                        title: 'Posts do Alano',
                        onTap: () => _changeTab(context, 2),
                      ),
                    ]),

                    // Botão destacado A CÚPULA
                    _buildCupulaButton(context),

                    _buildSection('Ferramentas', [
                      _buildDrawerItem(
                        icon: Icons.calculate_rounded,
                        title: 'Calculadora Forex',
                        onTap: () => _changeTab(context, 7),
                      ),
                      _buildDrawerItem(
                        icon: Icons.show_chart_rounded,
                        title: 'Sinais',
                        onTap: () => _changeTab(context, 3),
                      ),
                      _buildDrawerItem(
                        icon: Icons.business_center_rounded,
                        title: 'Portfólio',
                        onTap: () => _changeTab(context, 9),
                      ),
                      _buildDrawerItem(
                        icon: Icons.assessment_rounded,
                        title: 'Gerenciamento',
                        onTap: () => _changeTab(context, 15),
                      ),
                      _buildDrawerItem(
                        icon: Icons.event_note_rounded,
                        title: 'Calendário Econômico',
                        onTap: () => _changeTab(context, 14),
                      ),
                    ]),

                    _buildSection('Aprendizado', [
                      _buildDrawerItem(
                        icon: Icons.school_rounded,
                        title: 'Cursos',
                        onTap: () => _changeTab(context, 8),
                      ),
                      _buildDrawerItem(
                        icon: Icons.smart_toy_rounded,
                        title: 'Alano Crypto IA',
                        onTap: () => _changeTab(context, 10),
                      ),
                    ]),

                    _buildSection('Conta', [
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        title: 'Perfil',
                        onTap: () => _changeTab(context, 4),
                      ),
                      _buildDrawerItem(
                        icon: Icons.link_rounded,
                        title: 'Links úteis',
                        onTap: () => _changeTab(context, 11),
                      ),
                      _buildDrawerItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Suporte',
                        onTap: () => _changeTab(context, 12),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // BOTÃO DE LOGOUT
                    _buildLogoutButton(context),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha:0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha:0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alano CryptoFX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Menu Principal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryGreen.withValues(alpha:0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderDark.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCupulaButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCheckingAccess ? null : () => _handleCupulaTap(context),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha:0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withValues(alpha:0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha:0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha:0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha:0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'A CÚPULA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (_isCheckingAccess)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha:0.8),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Confirmar logout
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.cardDark,
                title: Text('Sair', style: TextStyle(color: AppTheme.textPrimary)),
                content: Text(
                  'Deseja realmente sair do aplicativo?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Sair', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sair',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red.shade400.withValues(alpha:0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeTab(BuildContext context, int index) {
    Navigator.pop(context);
    final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
    dashboardState?.changeTab(index);
  }
}
