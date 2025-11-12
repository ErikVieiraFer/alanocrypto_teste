import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent('Olá, preciso de ajuda com o AlanoCryptoFX.');
    final url = 'https://wa.me/5531988369268?text=$message';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.paddingMedium),

              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.gapLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suporte',
                          style: AppTheme.heading2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estamos aqui para ajudar',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.paddingXLarge),

              // Card principal melhorado
              Container(
                decoration: AppTheme.cardDecoration(hasGlow: true),
                padding: const EdgeInsets.all(AppTheme.paddingXLarge),
                child: Column(
                  children: [
                    // Ícone do WhatsApp
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.primaryGreen.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: AppTheme.paddingLarge),

                    Text(
                      'Como podemos ajudar?',
                      style: AppTheme.heading2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.gapMedium),

                    Text(
                      'Nossa equipe está disponível para responder suas dúvidas e resolver seus problemas rapidamente',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.paddingXLarge),

                    // Botão WhatsApp
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context),
                        style: AppTheme.primaryButton.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        icon: const Icon(Icons.chat, size: 24),
                        label: const Text(
                          'Abrir Chamado no WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Cards de informações adicionais
              _buildInfoCard(
                icon: Icons.access_time_rounded,
                title: 'Horário de Atendimento',
                description: 'Segunda a Sexta\n09:00 - 18:00',
              ),

              const SizedBox(height: AppTheme.gapMedium),

              _buildInfoCard(
                icon: Icons.speed_rounded,
                title: 'Tempo de Resposta',
                description: 'Até 24 horas úteis',
              ),

              const SizedBox(height: AppTheme.gapMedium),

              _buildInfoCard(
                icon: Icons.verified_user_rounded,
                title: 'Suporte Especializado',
                description: 'Equipe treinada em cripto',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: AppTheme.defaultRadius,
        border: Border.all(
          color: AppTheme.borderDark,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
