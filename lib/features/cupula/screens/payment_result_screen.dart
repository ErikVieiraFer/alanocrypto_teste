import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'cupula_main_screen.dart';

enum PaymentStatus { success, error, pending }

class PaymentResultScreen extends StatelessWidget {
  final PaymentStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PaymentResultScreen({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 32),
              Text(
                _getMainMessage(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getSubMessage(),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildActionButton(context),
              if (status == PaymentStatus.error && onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Voltar',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    Color backgroundColor;

    switch (status) {
      case PaymentStatus.success:
        icon = Icons.check_circle;
        color = AppTheme.primaryGreen;
        backgroundColor = AppTheme.primaryGreen.withValues(alpha: 0.2);
        break;
      case PaymentStatus.error:
        icon = Icons.error;
        color = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        break;
      case PaymentStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        break;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case PaymentStatus.success:
        return 'Pagamento Aprovado';
      case PaymentStatus.error:
        return 'Pagamento Falhou';
      case PaymentStatus.pending:
        return 'Processando';
    }
  }

  String _getMainMessage() {
    switch (status) {
      case PaymentStatus.success:
        return 'Parabéns! Você agora é membro da Cúpula!';
      case PaymentStatus.error:
        return 'Ops! Algo deu errado';
      case PaymentStatus.pending:
        return 'Pagamento em processamento';
    }
  }

  String _getSubMessage() {
    switch (status) {
      case PaymentStatus.success:
        return 'Seu acesso premium foi ativado com sucesso. Aproveite todos os benefícios exclusivos!';
      case PaymentStatus.error:
        return errorMessage ?? 'Não foi possível processar seu pagamento. Por favor, tente novamente.';
      case PaymentStatus.pending:
        return 'Seu pagamento está sendo processado. Você receberá uma notificação quando for aprovado.';
    }
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText;
    VoidCallback onPressed;
    Color buttonColor;

    switch (status) {
      case PaymentStatus.success:
        buttonText = 'Acessar A Cúpula';
        buttonColor = AppTheme.primaryGreen;
        onPressed = () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CupulaMainScreen()),
          );
        };
        break;
      case PaymentStatus.error:
        buttonText = 'Tentar Novamente';
        buttonColor = Colors.red;
        onPressed = () {
          if (onRetry != null) {
            Navigator.pop(context);
            onRetry!();
          } else {
            Navigator.pop(context);
          }
        };
        break;
      case PaymentStatus.pending:
        buttonText = 'Voltar ao Início';
        buttonColor = Colors.orange;
        onPressed = () => Navigator.pop(context);
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
