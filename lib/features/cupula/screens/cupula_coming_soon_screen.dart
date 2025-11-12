import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CupulaComingSoonScreen extends StatelessWidget {
  const CupulaComingSoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone com glow
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 60,
                      spreadRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 80,
                ),
              ),

              const SizedBox(height: 48),

              // Título
              const Text(
                'A CÚPULA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtítulo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'EM BREVE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Descrição
              Text(
                'Estamos preparando algo exclusivo para você.',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Fique ligado para novidades!',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Card informativo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.cardDark,
                      AppTheme.cardDark.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderDark.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.05),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seja notificado',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ative as notificações para ser o primeiro a saber quando A Cúpula estiver disponível.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
