import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../services/cupula_lives_service.dart';
import '../widgets/cupula_widgets.dart';
import 'cupula_live_watch_screen.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class CupulaLivesPreview extends StatefulWidget {
  const CupulaLivesPreview({super.key});

  @override
  State<CupulaLivesPreview> createState() => _CupulaLivesPreviewState();
}

class _CupulaLivesPreviewState extends State<CupulaLivesPreview>
    with TickerProviderStateMixin {
  final CupulaLivesService _livesService = CupulaLivesService();
  final PageController _pageController = PageController(viewportFraction: 0.95);
  late AnimationController _pulseController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;
  int _currentPage = 0;
  late Stream<List<CupulaLive>> _livesStream;

  @override
  void initState() {
    super.initState();
    _livesStream = _livesService.getLives();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _headerAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _openLiveScreen(CupulaLive live) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CupulaLiveWatchScreen(live: live),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<CupulaLive>>(
              stream: _livesStream,
              builder: (context, snapshot) {
                debugPrint('📺 Lives StreamBuilder - state: ${snapshot.connectionState}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (snapshot.hasError) {
                  debugPrint('❌ Lives error: ${snapshot.error}');
                  return _buildError(snapshot.error.toString());
                }

                final lives = snapshot.data ?? [];

                if (lives.isEmpty) {
                  return _buildEmpty();
                }

                final currentLive = lives.where((l) => l.isLive).toList();
                final recordings = lives.where((l) => !l.isLive).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (currentLive.isNotEmpty) ...[
                      _buildSectionTitle('AO VIVO AGORA', isLive: true),
                      const SizedBox(height: 12),
                      ...currentLive.asMap().entries.map((entry) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (entry.key * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: _LiveCard(
                            live: entry.value,
                            isHighlighted: true,
                            pulseController: _pulseController,
                            onTap: () => _openLiveScreen(entry.value),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                    if (recordings.isNotEmpty) ...[
                      _buildSectionTitle('Gravações'),
                      const SizedBox(height: 12),
                      _buildRecordedLivesCarousel(recordings),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFadeAnim,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _kNeonGreen.withValues(alpha: 0.15),
              _kNeonGreen.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: _kNeonGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kNeonGreen.withValues(alpha: 0.3),
                      _kNeonGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kNeonGreen.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kNeonGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  color: _kNeonGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lives da Cúpula',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ao vivo e gravações exclusivas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatsChip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsChip() {
    return StreamBuilder<List<CupulaLive>>(
      stream: _livesStream,
      builder: (context, snapshot) {
        final lives = snapshot.data ?? [];
        final liveCount = lives.where((l) => l.isLive).length;
        final isLiveNow = liveCount > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLiveNow
                ? AppTheme.errorRed.withValues(alpha: 0.15)
                : _kNeonGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLiveNow
                  ? AppTheme.errorRed.withValues(alpha: 0.3)
                  : _kNeonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLiveNow)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorRed.withValues(alpha: _pulseController.value),
                            blurRadius: 4,
                            spreadRadius: _pulseController.value * 2,
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Icon(
                  Icons.videocam_rounded,
                  color: _kNeonGreen,
                  size: 14,
                ),
              const SizedBox(width: 6),
              Text(
                isLiveNow ? '$liveCount ao vivo' : '${lives.length} vídeos',
                style: TextStyle(
                  color: isLiveNow ? AppTheme.errorRed : _kNeonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, {bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLive
            ? AppTheme.errorRed.withValues(alpha: 0.1)
            : _kNeonGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? AppTheme.errorRed.withValues(alpha: 0.2)
              : _kNeonGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorRed.withValues(alpha: _pulseController.value),
                        blurRadius: 6,
                        spreadRadius: _pulseController.value * 2,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Icon(
              Icons.videocam_rounded,
              size: 16,
              color: _kNeonGreen,
            ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isLive ? AppTheme.errorRed : _kNeonGreen,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedLivesCarousel(List<CupulaLive> recordedLives) {
    final pageCount = (recordedLives.length / 2).ceil();

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: pageCount,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * 2;
                  final endIndex = (startIndex + 2).clamp(0, recordedLives.length);
                  final pageLives = recordedLives.sublist(startIndex, endIndex);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        ...pageLives.map((live) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildLiveCard(live),
                            ),
                          );
                        }),
                        if (pageLives.length < 2)
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: 12),
            _buildPageIndicator(pageCount),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveCard(CupulaLive live) {
    return GestureDetector(
      onTap: () => _openLiveScreen(live),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _kNeonGreen.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      live.effectiveThumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF22282F),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 40,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    live.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(live.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF9ca3af),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? _kNeonGreen : const Color(0xFF22282F),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + index * 100),
          builder: (context, value, child) {
            return Opacity(
              opacity: value * 0.5,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 180,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: double.infinity, height: 18),
                        SizedBox(height: 8),
                        SkeletonLoader(width: 200, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erro ao carregar lives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNeonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kNeonGreen.withValues(alpha: 0.2),
                    _kNeonGreen.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.live_tv_outlined,
                size: 48,
                color: _kNeonGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma live disponível',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lives ao vivo e gravações\naparecerão aqui!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final CupulaLive live;
  final bool isHighlighted;
  final VoidCallback onTap;
  final AnimationController? pulseController;

  const _LiveCard({
    required this.live,
    required this.isHighlighted,
    required this.onTap,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? AppTheme.errorRed.withValues(alpha: 0.5)
                  : _kNeonGreen.withValues(alpha: 0.15),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? AppTheme.errorRed.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: isHighlighted ? 16 : 8,
                spreadRadius: isHighlighted ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      live.effectiveThumbnailUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.cardMedium,
                                AppTheme.cardDark,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 64,
                              color: _kNeonGreen.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: isHighlighted
                        ? _AnimatedLiveBadge(controller: pulseController!)
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _kNeonGreen,
                                  _kNeonGreen.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _kNeonGreen.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam_rounded, size: 12, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  'GRAVAÇÃO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppTheme.errorRed
                            : _kNeonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isHighlighted ? AppTheme.errorRed : _kNeonGreen)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        isHighlighted ? Icons.live_tv_rounded : Icons.play_arrow_rounded,
                        size: 28,
                        color: isHighlighted ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      live.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (live.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        live.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: _kNeonGreen.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            live.authorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isHighlighted
                                    ? [
                                        AppTheme.errorRed,
                                        AppTheme.errorRed.withValues(alpha: 0.8),
                                      ]
                                    : [
                                        _kNeonGreen,
                                        _kNeonGreen.withValues(alpha: 0.8),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isHighlighted ? AppTheme.errorRed : _kNeonGreen)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHighlighted ? Icons.live_tv_rounded : Icons.play_arrow_rounded,
                                  size: 14,
                                  color: isHighlighted ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isHighlighted ? 'Assistir ao vivo' : 'Assistir',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isHighlighted ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _AnimatedLiveBadge extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedLiveBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorRed.withValues(alpha: 0.3 + (controller.value * 0.4)),
                blurRadius: 8 + (controller.value * 6),
                spreadRadius: controller.value * 3,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: controller.value),
                      blurRadius: 6,
                      spreadRadius: controller.value * 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
