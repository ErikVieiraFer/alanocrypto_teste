import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/payment_service.dart';

const Color kNeonGreen = Color(0xFF00FF88);
const Color kLiveRed = Color(0xFFFF4444);

class CupulaSalesScreen extends StatefulWidget {
  const CupulaSalesScreen({super.key});

  @override
  State<CupulaSalesScreen> createState() => _CupulaSalesScreenState();
}

class _CupulaSalesScreenState extends State<CupulaSalesScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnimations;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Staggered animation for cards
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for 4 cards
    _cardAnimations = List.generate(4, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        ),
      );
    });

    // Shimmer animation for title
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // Start animations
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);

    try {
      await _paymentService.openCheckout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HERO SECTION
          _HeroSection(shimmerController: _shimmerController),
          SizedBox(height: 80),

          // Grid de features com animação staggered
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = 20.0;
              final availableWidth = screenWidth - (horizontalPadding * 2);

              int crossAxisCount = 2;
              if (screenWidth < 360) {
                crossAxisCount = 1;
              }

              final cardWidth =
                  (availableWidth / crossAxisCount) - (crossAxisCount > 1 ? 6 : 0);
              final cardHeight = cardWidth * 0.85;
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
                        fontWeight: FontWeight.w900,
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
                        _AnimatedFeatureCard(
                          animation: _cardAnimations[0],
                          child: _GlassFeatureCard(
                            icon: Icons.candlestick_chart_rounded,
                            title: 'Sinais Premium',
                            description:
                                'Análises técnicas detalhadas com stop loss, take profit e estratégias comprovadas',
                            iconColor: kNeonGreen,
                            badge: 'Mais Popular',
                          ),
                        ),
                        _AnimatedFeatureCard(
                          animation: _cardAnimations[1],
                          child: _GlassFeatureCard(
                            icon: Icons.forum_rounded,
                            title: 'Chat Exclusivo',
                            description:
                                'Converse com membros premium e interaja diretamente com o Calango',
                            iconColor: kNeonGreen,
                          ),
                        ),
                        _AnimatedFeatureCard(
                          animation: _cardAnimations[2],
                          child: _GlassFeatureCard(
                            icon: Icons.auto_stories_rounded,
                            title: 'Posts Premium',
                            description:
                                'Conteúdo educativo exclusivo com estratégias avançadas do mercado',
                            iconColor: kNeonGreen,
                          ),
                        ),
                        _AnimatedFeatureCard(
                          animation: _cardAnimations[3],
                          child: _GlassFeatureCard(
                            icon: Icons.live_tv_rounded,
                            title: 'Lives ao Vivo',
                            description:
                                'Análises de mercado em tempo real e operações ao vivo com o Calango',
                            iconColor: kLiveRed,
                            badge: 'Novo',
                            badgeColor: kLiveRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 80),

          // Seção de Comparação
          _ComparisonSection(),
          SizedBox(height: 80),

          // Preço com animação e botão CTA
          _PulsatingPrice(
            isLoading: _isLoading,
            onSubscribe: _handleSubscribe,
          ),
          SizedBox(height: 24),

          // Textos de reassurance
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ReassuranceText(
                    icon: Icons.check_circle_outline, text: 'Acesso imediato'),
                SizedBox(width: 16),
                _ReassuranceText(
                    icon: Icons.cancel_outlined, text: 'Cancele quando quiser'),
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

// Animated wrapper for staggered card entry
class _AnimatedFeatureCard extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedFeatureCard({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }
}

// Glassmorphism Feature Card with Material Icons
class _GlassFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;

  const _GlassFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 32.0 : 36.0;
    final titleSize = screenWidth < 360 ? 14.0 : 15.0;
    final descriptionSize = screenWidth < 360 ? 11.5 : 12.0;
    final cardPadding = screenWidth < 360 ? 14.0 : 16.0;
    final effectiveBadgeColor = badgeColor ?? kNeonGreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon in glowing circle
              Container(
                width: iconSize + 36,
                height: iconSize + 36,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.3),
                      iconColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withValues(alpha: 0.25),
                        iconColor.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Title
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

              // Badge space (fixed height)
              SizedBox(height: 4),
              SizedBox(
                height: 18,
                child: badge != null
                    ? Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              effectiveBadgeColor,
                              effectiveBadgeColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: effectiveBadgeColor.withValues(alpha: 0.6),
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
                    : SizedBox.shrink(),
              ),

              SizedBox(height: 4),

              // Description
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
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AnimationController shimmerController;

  const _HeroSection({required this.shimmerController});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = screenWidth < 360 ? 40.0 : 48.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Shimmer title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        kNeonGreen,
                        Colors.white,
                        kNeonGreen,
                      ],
                      stops: [
                        (shimmerController.value - 0.3).clamp(0.0, 1.0),
                        shimmerController.value,
                        (shimmerController.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'A CÚPULA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),

          // Tagline
          Text(
            'Opere como um profissional',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
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

          // Statistics
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
            fontWeight: FontWeight.w900,
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
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 24),
          // Glassmorphism comparison table
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor.withValues(alpha: 0.5),
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

                    // Comparison rows
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
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Free column
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFree ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: hasFree
                      ? AppTheme.successGreen
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
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
            color: Colors.white.withValues(alpha: 0.05),
          ),

          // Premium column
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPremium ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: hasPremium
                      ? kNeonGreen
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
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

class _PulsatingPrice extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onSubscribe;

  const _PulsatingPrice({
    required this.isLoading,
    required this.onSubscribe,
  });

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
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
                      // Old price crossed out
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

                      // Main price
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
                              fontWeight: FontWeight.w900,
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

                      // Savings badge with icon
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Icon(
                              Icons.savings_rounded,
                              color: Colors.white,
                              size: 18,
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

                      // Daily value
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
                                Icon(
                                  Icons.coffee_rounded,
                                  color: AppTheme.warningOrange,
                                  size: 20,
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

                      // Benefits
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
                      SizedBox(height: 24),

                      // CTA Button with scale animation on tap
                      _AnimatedCTAButton(
                        isLoading: widget.isLoading,
                        onPressed: widget.onSubscribe,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedCTAButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedCTAButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_AnimatedCTAButton> createState() => _AnimatedCTAButtonState();
}

class _AnimatedCTAButtonState extends State<_AnimatedCTAButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
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
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              disabledBackgroundColor: kNeonGreen.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.backgroundColor,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Abrindo checkout...',
                        style: TextStyle(
                          color: AppTheme.backgroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium,
                          color: AppTheme.backgroundColor, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'QUERO SER MEMBRO',
                        style: TextStyle(
                          color: AppTheme.backgroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
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
