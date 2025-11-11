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
      color: AppTheme.backgroundBlack,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.paddingXLarge + AppTheme.gapSmall),

              Text(
                'Ajuda',
                style: AppTheme.heading1,
              ),

              const SizedBox(height: AppTheme.gapSmall),

              Text(
                'Fale com nossa equipe',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 60),

              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: AppTheme.largeRadius,
                    boxShadow: [AppTheme.cardShadowStrong],
                  ),
                  padding: const EdgeInsets.all(AppTheme.paddingXLarge + AppTheme.gapSmall),
                  child: Column(
                    children: [
                      Text(
                        'Como podemos ajudar?',
                        style: AppTheme.heading2,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.gapMedium),

                      Text(
                        'Abra um chamado e nossa equipe te responderá em breve',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.paddingXLarge),

                      ElevatedButton(
                        onPressed: () => _openWhatsApp(context),
                        style: AppTheme.primaryButton.copyWith(
                          minimumSize: const WidgetStatePropertyAll(Size(200, 48)),
                        ),
                        child: Text(
                          'Abrir Chamado',
                          style: AppTheme.buttonText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
