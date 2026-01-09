import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CupulaChatPreview extends StatelessWidget {
  const CupulaChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final mockMessages = [
      {'user': 'Calango', 'avatar': '🦎', 'text': 'Bom dia galera! Vamos operar hoje? 🚀', 'time': '09:15'},
      {'user': 'Trader01', 'avatar': '👤', 'text': 'Fala mestre! Pronto pra ação!', 'time': '09:16'},
      {'user': 'Erik', 'avatar': '👨‍💻', 'text': 'Prontos para operar! EUR/USD tá bom hoje', 'time': '09:17'},
      {'user': 'MariaTrader', 'avatar': '👩', 'text': 'Alguém viu o RSI do BTC?', 'time': '09:18'},
      {'user': 'Calango', 'avatar': '🦎', 'text': 'BTC tá sobrecomprado, cuidado com entrada agora', 'time': '09:19'},
      {'user': 'JoãoFX', 'avatar': '👨', 'text': 'Valeu pela dica! 🙏', 'time': '09:20'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Row(
          children: [
            Text('💬'),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat Exclusivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Prévia - Em breve',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner de prévia
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: AppTheme.greenTransparent20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 18),
                SizedBox(width: 8),
                Text(
                  'Esta é apenas uma prévia do chat premium',
                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
                ),
              ],
            ),
          ),
          // Mensagens
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: mockMessages.length,
              itemBuilder: (context, index) {
                final msg = mockMessages[index];
                final isCalango = msg['user'] == 'Calango';

                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCalango ? AppTheme.primaryGreen : AppTheme.cardMedium,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(msg['avatar']!, style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Mensagem
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  msg['user']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCalango ? AppTheme.primaryGreen : AppTheme.textPrimary,
                                  ),
                                ),
                                if (isCalango) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                                Spacer(),
                                Text(
                                  msg['time']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              msg['text']!,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Input desabilitado
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              border: Border(top: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Mensagem disponível em breve...',
                      style: TextStyle(color: AppTheme.textTertiary),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardMedium,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
