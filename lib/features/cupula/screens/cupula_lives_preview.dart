import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CupulaLivesPreview extends StatelessWidget {
  const CupulaLivesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final mockLives = [
      {
        'title': '🔴 AO VIVO: Análise de Mercado',
        'host': 'Calango',
        'viewers': '127',
        'isLive': true,
        'thumbnail': '📊',
        'time': 'Agora',
      },
      {
        'title': 'Estratégias para EUR/USD',
        'host': 'Calango',
        'viewers': null,
        'isLive': false,
        'thumbnail': '💱',
        'time': 'Hoje às 14:00',
      },
      {
        'title': 'Como operar em tendências',
        'host': 'Erik',
        'viewers': null,
        'isLive': false,
        'thumbnail': '📈',
        'time': 'Amanhã às 10:00',
      },
      {
        'title': 'Trade ao vivo: Bitcoin',
        'host': 'Calango',
        'viewers': null,
        'isLive': false,
        'thumbnail': '₿',
        'time': 'Sex às 16:00',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Row(
          children: [
            Text('📺'),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lives ao Vivo',
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
                  'Esta é apenas uma prévia das lives premium',
                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
                ),
              ],
            ),
          ),
          // Lista de lives
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: mockLives.length,
              itemBuilder: (context, index) {
                final live = mockLives[index];
                final isLive = live['isLive'] as bool;

                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLive ? AppTheme.errorRed : AppTheme.borderDark,
                        width: isLive ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail com status
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    isLive ? AppTheme.redTransparent20 : AppTheme.cardMedium,
                                    isLive ? AppTheme.redTransparent10 : AppTheme.cardLight,
                                  ],
                                ),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: Center(
                                child: Text(
                                  live['thumbnail'] as String,
                                  style: TextStyle(fontSize: 64),
                                ),
                              ),
                            ),
                            // Badge de status
                            if (isLive)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'AO VIVO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Viewers count
                            if (live['viewers'] != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundBlack,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.remove_red_eye, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        live['viewers'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Info da live
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                live['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        live['host'] == 'Calango' ? '🦎' : '👨‍💻',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    live['host'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(Icons.schedule, size: 14, color: AppTheme.textTertiary),
                                  SizedBox(width: 4),
                                  Text(
                                    live['time'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isLive) ...[
                                SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cardMedium,
                                      disabledBackgroundColor: AppTheme.cardMedium,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Disponível em breve',
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
