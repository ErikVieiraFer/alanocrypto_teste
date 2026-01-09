import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CupulaPostsPreview extends StatelessWidget {
  const CupulaPostsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final mockPosts = [
      {
        'title': '5 Estratégias Avançadas de Forex',
        'excerpt': 'Descubra as técnicas que profissionais usam para maximizar lucros e minimizar riscos no mercado de câmbio.',
        'image': '📈',
        'date': 'Há 2 horas',
        'category': 'Estratégia',
      },
      {
        'title': 'Análise Profunda: EUR/USD',
        'excerpt': 'Tendência de alta confirmada. Análise técnica completa com níveis de suporte e resistência.',
        'image': '💹',
        'date': 'Ontem',
        'category': 'Análise',
      },
      {
        'title': 'Gestão de Risco para Iniciantes',
        'excerpt': 'Aprenda a proteger seu capital com técnicas comprovadas de gestão de risco.',
        'image': '🛡️',
        'date': 'Há 3 dias',
        'category': 'Educação',
      },
      {
        'title': 'Como Operar em Mercados Voláteis',
        'excerpt': 'Estratégias para aproveitar oportunidades quando o mercado está agitado.',
        'image': '⚡',
        'date': 'Há 5 dias',
        'category': 'Estratégia',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Row(
          children: [
            Text('📰'),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posts Premium',
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
          // Banner
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
                  'Esta é apenas uma prévia dos posts premium',
                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
                ),
              ],
            ),
          ),
          // Posts
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: mockPosts.length,
              itemBuilder: (context, index) {
                final post = mockPosts[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderDark,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardMedium,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(post['image']!, style: TextStyle(fontSize: 30)),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.greenTransparent20,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        post['category']!,
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      post['date']!,
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            post['title']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            post['excerpt']!,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ler mais >',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.lock, color: AppTheme.textTertiary, size: 18),
                            ],
                          ),
                        ],
                      ),
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
