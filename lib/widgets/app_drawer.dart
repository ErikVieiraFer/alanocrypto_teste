import 'package:flutter/material.dart';
import 'package:alanoapp/theme/app_theme.dart';
import '../features/dashboard/screen/dashboard_screen.dart';

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
              icon: Icons.home,
              title: 'Home',
              onTap: () => _changeTab(context, 0),
            ),

            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'Mercado',
              onTap: () => _changeTab(context, 5),
            ),

            _buildDrawerItem(
              icon: Icons.star,
              title: 'Watchlist',
              onTap: () => _changeTab(context, 6),
            ),

            _buildDrawerItem(
              icon: Icons.people,
              title: 'Comunidade',
              onTap: () => _changeTab(context, 1),
            ),

            _buildDrawerItem(
              icon: Icons.calculate,
              title: 'Calculadora Forex',
              onTap: () => _changeTab(context, 7),
            ),

            _buildDrawerItem(
              icon: Icons.school,
              title: 'Cursos',
              onTap: () => _changeTab(context, 8),
            ),

            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Sinais',
              onTap: () => _changeTab(context, 3),
            ),

            _buildDrawerItem(
              icon: Icons.article,
              title: 'Posts do Alano',
              onTap: () => _changeTab(context, 2),
            ),

            _buildDrawerItem(
              icon: Icons.business_center,
              title: 'Portfólio',
              onTap: () => _changeTab(context, 9),
            ),

            _buildDrawerItem(
              icon: Icons.android,
              title: 'Alano Crypto IA',
              onTap: () => _changeTab(context, 10),
            ),

            _buildDrawerItem(
              icon: Icons.person,
              title: 'Perfil',
              onTap: () => _changeTab(context, 4),
            ),

            Divider(color: Colors.grey.shade800, height: 32),

            _buildDrawerItem(
              icon: Icons.link,
              title: 'Links úteis',
              onTap: () => _changeTab(context, 11),
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Suporte',
              onTap: () => _changeTab(context, 12),
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

  void _changeTab(BuildContext context, int index) {
    Navigator.pop(context);
    final dashboardState = context.findAncestorStateOfType<DashboardScreenState>();
    dashboardState?.changeTab(index);
  }
}
