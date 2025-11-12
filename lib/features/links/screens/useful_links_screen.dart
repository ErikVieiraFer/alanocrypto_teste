import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state.dart';

class UsefulLinksScreen extends StatelessWidget {
  const UsefulLinksScreen({super.key});

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'briefcase':
        return Icons.business_center;
      case 'trending_up':
        return Icons.trending_up;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'video_library':
        return Icons.video_library;
      case 'camera_alt':
        return Icons.camera_alt;
      default:
        return Icons.link;
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Não foi possível abrir o link'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.defaultRadius,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao abrir o link'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.defaultRadius,
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copiado!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.defaultRadius,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLinkCard(Map<String, dynamic> link) {
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.gapMedium),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: AppTheme.largeRadius,
            border: Border.all(color: AppTheme.borderDark, width: 1),
          ),
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.cardMedium,
                  borderRadius: AppTheme.defaultRadius,
                ),
                child: Icon(
                  _getIconFromString(link['icon'] ?? 'link'),
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              SizedBox(width: AppTheme.gapMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link['title'] ?? '',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link['description'] ?? '',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: AppTheme.gapSmall),
                    Text(
                      link['url'] ?? '',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: AppTheme.gapMedium),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openLink(context, link['url'] ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.defaultRadius,
                              ),
                              minimumSize: const Size.fromHeight(40),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.open_in_new, size: 16),
                                const SizedBox(width: 8),
                                const Text('Abrir'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _copyLink(context, link['url'] ?? ''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: BorderSide(color: AppTheme.borderDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.defaultRadius,
                              ),
                              minimumSize: const Size.fromHeight(40),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.copy, size: 16),
                                const SizedBox(width: 8),
                                const Text('Copiar'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 40,
              left: AppTheme.paddingLarge,
              right: AppTheme.paddingLarge,
              bottom: AppTheme.paddingLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Links úteis', style: AppTheme.heading1),
                const SizedBox(height: 8),
                Text(
                  'Acesse e compartilhe nossos links oficiais',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('useful_links')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Erro ao carregar links',
                    message: 'Tente novamente mais tarde',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.link_off,
                    title: 'Nenhum link disponível',
                    message: 'Links úteis serão adicionados em breve',
                  );
                }

                final allLinks = snapshot.data!.docs;
                final links = allLinks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isActive'] == true;
                }).toList();

                if (links.isEmpty) {
                  return const EmptyState(
                    icon: Icons.link_off,
                    title: 'Nenhum link disponível',
                    message: 'Links úteis serão adicionados em breve',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                  ),
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final linkData = links[index].data() as Map<String, dynamic>;
                    return _buildLinkCard(linkData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
