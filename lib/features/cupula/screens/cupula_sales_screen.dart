import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'cupula_main_screen.dart';

// Verde néon para destaques
const Color kNeonGreen = Color(0xFF00FF88);

class CupulaSalesScreen extends StatelessWidget {
  const CupulaSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            _HeroSection(),
            SizedBox(height: 80), // Espaçamento golden ratio

            // Grid de features
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final horizontalPadding = 20.0;
                final availableWidth = screenWidth - (horizontalPadding * 2);

                // Calcula número de colunas baseado na largura da tela
                int crossAxisCount = 2;
                if (screenWidth < 360) {
                  crossAxisCount = 1; // Telas muito pequenas
                }

                // Calcula aspect ratio dinamicamente
                // Para 2 colunas: (largura disponível / 2 - espaçamento) / altura desejada
                final cardWidth = (availableWidth / crossAxisCount) - (crossAxisCount > 1 ? 6 : 0);
                final cardHeight = cardWidth * 0.85; // Proporção altura/largura (cards mais baixos)
                final aspectRatio = cardWidth / cardHeight;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O que você terá acesso:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900, // Extra bold
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                        children: [
                          _FeatureCard(
                            emoji: '📊',
                            title: 'Sinais Premium',
                            description: 'Análises técnicas detalhadas com stop loss, take profit e estratégias comprovadas',
                            gradientColors: [AppTheme.primaryGreen.withValues(alpha: 0.25), AppTheme.primaryGreen.withValues(alpha: 0.08)],
                            badge: 'Mais Popular',
                            badgeColor: AppTheme.primaryGreen,
                          ),
                          _FeatureCard(
                            emoji: '💬',
                            title: 'Chat Exclusivo',
                            description: 'Converse com membros premium e interaja diretamente com o Calango',
                            gradientColors: [AppTheme.primaryGreen.withValues(alpha: 0.25), AppTheme.primaryGreen.withValues(alpha: 0.08)],
                          ),
                          _FeatureCard(
                            emoji: '📰',
                            title: 'Posts Premium',
                            description: 'Conteúdo educativo exclusivo com estratégias avançadas do mercado',
                            gradientColors: [AppTheme.primaryGreen.withValues(alpha: 0.25), AppTheme.primaryGreen.withValues(alpha: 0.08)],
                          ),
                          _FeatureCard(
                            emoji: '📺',
                            title: 'Lives ao Vivo',
                            description: 'Análises de mercado em tempo real e operações ao vivo com o Calango',
                            gradientColors: [AppTheme.primaryGreen.withValues(alpha: 0.25), AppTheme.primaryGreen.withValues(alpha: 0.08)],
                            badge: 'Novo',
                            badgeColor: AppTheme.primaryGreen,
                            emojiOffsetY: -12.0, // Move o emoji da TV para cima
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 80), // Espaçamento golden ratio

            // Seção de Comparação
            _ComparisonSection(),
            SizedBox(height: 80), // Espaçamento golden ratio

            // Preço com animação
            _PulsatingPrice(),
            SizedBox(height: 50),

            // Botões CTA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Botão Principal - Assinar
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonGreen.withValues(alpha: 0.6),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: kNeonGreen.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.info_outline, color: kNeonGreen),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text('Pagamento em breve! Entre em contato com o suporte.'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.cardDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNeonGreen,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🚀', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Text(
                              'QUERO ENTRAR NA CÚPULA',
                              style: TextStyle(
                                color: AppTheme.backgroundColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Textos de reassurance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ReassuranceText(icon: Icons.check_circle_outline, text: 'Acesso imediato'),
                      SizedBox(width: 16),
                      _ReassuranceText(icon: Icons.cancel_outlined, text: 'Cancele quando quiser'),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Divisor
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.borderDark.withValues(alpha: 0.3))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.borderDark.withValues(alpha: 0.3))),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Botão Secundário - Ver Prévia
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CupulaMainScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kNeonGreen, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎁', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'VER PRÉVIA GRÁTIS',
                            style: TextStyle(
                              color: kNeonGreen,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Texto explicativo
                  Text(
                    'Explore antes de assinar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Banner YouTube
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final bannerFontSize = screenWidth < 360 ? 12.0 : 13.0;
                final bannerPadding = screenWidth < 360 ? 12.0 : 16.0;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(bannerPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.warningOrange,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Membros do canal do YouTube do Alano, entre em contato com o suporte para liberação de acesso!',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: bannerFontSize,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 40),
          ],
        ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = screenWidth < 360 ? 40.0 : 48.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Título com gradiente
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  kNeonGreen,
                  AppTheme.successGreen,
                  kNeonGreen,
                ],
              ).createShader(bounds),
              child: Text(
                'A CÚPULA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900, // Extra bold
                  color: Colors.white,
                  letterSpacing: 6, // Aumentado
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Tagline impactante
          Text(
            'Opere como um profissional',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2, // Aumentado
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Junte-se aos traders de elite',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 32),

          // Estatísticas
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatisticItem(
                  value: '432+',
                  label: 'Membros\nAtivos',
                  icon: Icons.people_rounded,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.borderDark.withValues(alpha: 0.3),
                ),
                _StatisticItem(
                  value: '85%',
                  label: 'Taxa de\nAcerto',
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatisticItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kNeonGreen.withValues(alpha: 0.2),
                kNeonGreen.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kNeonGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: kNeonGreen,
            size: 24,
          ),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900, // Extra bold
            color: kNeonGreen,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            height: 1.3,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare os planos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900, // Extra bold
              color: AppTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderDark.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GRATUITO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.borderDark.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kNeonGreen.withValues(alpha: 0.3),
                                kNeonGreen.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kNeonGreen.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kNeonGreen.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'A CÚPULA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: kNeonGreen,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Linhas de comparação
                _ComparisonRow(
                  freeText: 'Sinais básicos',
                  premiumText: 'Sinais premium',
                  hasFree: false,
                  hasPremium: true,
                ),
                _ComparisonRow(
                  freeText: 'Chat aberto',
                  premiumText: 'Chat exclusivo',
                  hasFree: false,
                  hasPremium: true,
                ),
                _ComparisonRow(
                  freeText: 'Posts simples',
                  premiumText: 'Posts exclusivos',
                  hasFree: false,
                  hasPremium: true,
                ),
                _ComparisonRow(
                  freeText: 'Sem lives',
                  premiumText: 'Lives exclusivas',
                  hasFree: false,
                  hasPremium: true,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String freeText;
  final String premiumText;
  final bool hasFree;
  final bool hasPremium;
  final bool isLast;

  const _ComparisonRow({
    required this.freeText,
    required this.premiumText,
    required this.hasFree,
    required this.hasPremium,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.borderDark.withValues(alpha: 0.2),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Coluna Gratuito
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFree ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: hasFree ? AppTheme.successGreen : AppTheme.textSecondary.withValues(alpha: 0.5),
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    freeText,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFree ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 30,
            color: AppTheme.borderDark.withValues(alpha: 0.2),
          ),

          // Coluna Premium
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPremium ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: hasPremium ? kNeonGreen : AppTheme.textSecondary.withValues(alpha: 0.5),
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    premiumText,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPremium ? kNeonGreen : AppTheme.textSecondary,
                      fontWeight: hasPremium ? FontWeight.w700 : FontWeight.normal,
                    ),
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

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final String? badge;
  final Color? badgeColor;
  final double emojiOffsetY; // Offset vertical do emoji

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradientColors,
    this.badge,
    this.badgeColor,
    this.emojiOffsetY = 0.0, // Default sem offset
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajusta tamanhos baseado na largura da tela
    final emojiSize = screenWidth < 360 ? 50.0 : 60.0;
    final titleSize = screenWidth < 360 ? 14.0 : 15.0;
    final descriptionSize = screenWidth < 360 ? 11.5 : 12.0;
    final cardPadding = screenWidth < 360 ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withValues(alpha: 0.15),
            gradientColors[1].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.1),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji em círculo colorido
          Container(
            width: emojiSize + 20,
            height: emojiSize + 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withValues(alpha: 0.3),
                  gradientColors[1].withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: gradientColors[0].withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Transform.translate(
                offset: Offset(0, emojiOffsetY),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),

          // Título
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
            ),
          ),

          // ESPAÇAMENTO FIXO para badge (sempre 18px de altura)
          SizedBox(height: 4),
          SizedBox(
            height: 18, // ← ALTURA FIXA para todos os cards
            child: badge != null
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kNeonGreen,
                          kNeonGreen.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: kNeonGreen.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: AppTheme.backgroundColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                : SizedBox.shrink(), // ← Espaço vazio se não tem badge
          ),

          // ESPAÇAMENTO FIXO (sempre 4)
          SizedBox(height: 4),

          // Descrição
          Flexible(
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: descriptionSize,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsatingPrice extends StatefulWidget {
  const _PulsatingPrice();

  @override
  State<_PulsatingPrice> createState() => _PulsatingPriceState();
}

class _PulsatingPriceState extends State<_PulsatingPrice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajusta tamanhos baseado na largura da tela
    final containerPadding = screenWidth < 360 ? 20.0 : 24.0;
    final mainPriceSize = screenWidth < 360 ? 64.0 : 72.0;
    final symbolSize = screenWidth < 360 ? 28.0 : 32.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.3),
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                // Preço antigo riscado
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DE ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'R\$ 199,90',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppTheme.errorRed,
                        decorationThickness: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // "Por apenas"
                Text(
                  'POR APENAS',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),

                // Preço principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: symbolSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '149',
                      style: TextStyle(
                        fontSize: mainPriceSize,
                        fontWeight: FontWeight.w900, // Extra bold
                        color: Colors.white,
                        height: 0.9,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      ',90',
                      style: TextStyle(
                        fontSize: symbolSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'por mês',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),

                // Badge de economia
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successGreen,
                        AppTheme.successGreen.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successGreen.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '💰',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Economize R\$ 50!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Valor por dia
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'R\$ 4,99/dia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '☕',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Menos que um café!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Benefícios
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Você recebe:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      _BenefitItem(text: 'Sinais ilimitados'),
                      _BenefitItem(text: 'Chat exclusivo 24/7'),
                      _BenefitItem(text: 'Lives toda semana'),
                      _BenefitItem(text: 'Acesso vitalício aos posts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;

  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primaryGreen,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReassuranceText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReassuranceText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: kNeonGreen,
          size: 16,
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
