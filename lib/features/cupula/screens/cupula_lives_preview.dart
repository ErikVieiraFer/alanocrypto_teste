import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../widgets/cupula_widgets.dart';

class CupulaLivesPreview extends StatefulWidget {
  const CupulaLivesPreview({super.key});

  @override
  State<CupulaLivesPreview> createState() => _CupulaLivesPreviewState();
}

class _CupulaLivesPreviewState extends State<CupulaLivesPreview> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simular loading de 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

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
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.appBarColor,
        title: Row(
          children: [
            Text('📺'),
            SizedBox(width: 8),
            Text(
              'Lives ao Vivo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const SkeletonCard(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockLives.length,
              itemBuilder: (context, index) {
                final live = mockLives[index];
                final isLive = live['isLive'] as bool;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
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
                              const Positioned(
                                top: 12,
                                left: 12,
                                child: LiveBadge(),
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
                  ),
                );
              },
            ),
    );
  }
}
