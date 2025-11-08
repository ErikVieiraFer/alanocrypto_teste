import 'package:flutter/material.dart';
import 'package:alanoapp/theme/app_theme.dart';

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
            SizedBox(height: 16),

            // Mercados
            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'Mercados',
              onTap: () => _navigateTo(context, '/under-development', 'Mercados'),
            ),

            // Comunidade
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Comunidade',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 0},
                );
              },
            ),

            // Calculadora Forex
            _buildDrawerItem(
              icon: Icons.calculate,
              title: 'Calculadora Forex',
              onTap: () => _navigateTo(context, '/under-development', 'Calculadora Forex'),
            ),

            // Cursos
            _buildDrawerItem(
              icon: Icons.school,
              title: 'Cursos',
              onTap: () => _navigateTo(context, '/under-development', 'Cursos'),
            ),

            // Sinais
            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Sinais',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                  arguments: {'initialTab': 4},
                );
              },
            ),

            // Posts do Alano
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

            // Portfólio
            _buildDrawerItem(
              icon: Icons.business_center,
              title: 'Portfólio',
              onTap: () => _navigateTo(context, '/under-development', 'Portfólio'),
            ),

            // Gerenciamento
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Gerenciamento',
              onTap: () => _navigateTo(context, '/under-development', 'Gerenciamento'),
            ),

            // Alano Crypto IA
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

            // Watchlist
            _buildDrawerItem(
              icon: Icons.star,
              title: 'Watchlist',
              onTap: () => _navigateTo(context, '/under-development', 'Watchlist'),
            ),

            Divider(color: Colors.grey.shade800, height: 32),

            // Links úteis
            _buildDrawerItem(
              icon: Icons.link,
              title: 'Links úteis',
              onTap: () => _navigateTo(context, '/under-development', 'Links úteis'),
            ),

            // Suporte
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Suporte',
              onTap: () => _navigateTo(context, '/under-development', 'Suporte'),
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
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _navigateTo(BuildContext context, String route, String pageName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route, arguments: pageName);
  }
}
