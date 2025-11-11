import 'package:flutter/material.dart';
import 'package:alanoapp/theme/app_theme.dart';
import '../features/crypto/screens/market_screen.dart';
import '../features/crypto/screens/watchlist_screen.dart';
import '../features/transactions/screens/transactions_screen.dart';
import '../features/forex/screens/forex_calculator_screen.dart';
import '../features/courses/screens/courses_screen.dart';
import '../features/portfolio/screens/portfolio_screen.dart';
import '../features/support/screens/support_screen.dart';
import '../features/links/screens/useful_links_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 16),

            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'Mercado',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.star,
              title: 'Watchlist',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WatchlistScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.swap_horiz,
              title: 'Transações',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.people,
              title: 'Comunidade',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 1},
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.calculate,
              title: 'Calculadora Forex',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForexCalculatorScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.school,
              title: 'Cursos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CoursesScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Sinais',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 3},
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.article,
              title: 'Posts do Alano',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 2},
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.business_center,
              title: 'Portfólio',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PortfolioScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Gerenciamento',
              onTap: () => _navigateTo(context, '/under-development', 'Gerenciamento'),
            ),

            _buildDrawerItem(
              icon: Icons.android,
              title: 'Alano Crypto IA',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 3},
                );
              },
            ),

            Divider(color: Colors.grey.shade800, height: 32),

            _buildDrawerItem(
              icon: Icons.link,
              title: 'Links úteis',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsefulLinksScreen()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Suporte',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _navigateTo(BuildContext context, String route, String pageName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route, arguments: pageName);
  }
}
