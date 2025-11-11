import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.textSecondary),
            SizedBox(height: AppTheme.gapLarge),
            Text(title, style: AppTheme.heading2, textAlign: TextAlign.center),
            SizedBox(height: AppTheme.gapSmall),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: AppTheme.gapXLarge),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: AppTheme.primaryButton,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
