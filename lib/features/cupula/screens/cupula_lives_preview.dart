import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../services/cupula_lives_service.dart';
import '../widgets/cupula_widgets.dart';
import 'cupula_live_watch_screen.dart';

class CupulaLivesPreview extends StatefulWidget {
  const CupulaLivesPreview({super.key});

  @override
  State<CupulaLivesPreview> createState() => _CupulaLivesPreviewState();
}

class _CupulaLivesPreviewState extends State<CupulaLivesPreview> with SingleTickerProviderStateMixin {
  final CupulaLivesService _livesService = CupulaLivesService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
              stream: _livesService.getLives(),
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
                      _buildSectionTitle('🔴 AO VIVO AGORA', isLive: true),
                      const SizedBox(height: 12),
                      ...currentLive.map((live) => _LiveCard(
                        live: live,
                        isHighlighted: true,
                        pulseController: _pulseController,
                        onTap: () => _openLiveScreen(live),
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (recordings.isNotEmpty) ...[
                      _buildSectionTitle('📺 Gravações'),
                      const SizedBox(height: 12),
                      ...recordings.map((live) => _LiveCard(
                        live: live,
                        isHighlighted: false,
                        onTap: () => _openLiveScreen(live),
                      )),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.live_tv, color: AppTheme.primaryGreen, size: 24),
          SizedBox(width: 12),
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
    );
  }

  Widget _buildSectionTitle(String title, {bool isLive = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isLive ? AppTheme.errorRed : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
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
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar lives',
              style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.live_tv_outlined,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma live disponível',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lives ao vivo e gravações\naparecerão aqui!',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
                  ? AppTheme.errorRed
                  : AppTheme.borderDark.withValues(alpha: 0.3),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: AppTheme.errorRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
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
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: AppTheme.textSecondary,
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
                            Colors.black.withValues(alpha: 0.5),
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
                              color: AppTheme.cardDark.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.videocam, size: 14, color: AppTheme.primaryGreen),
                                SizedBox(width: 4),
                                Text(
                                  'GRAVAÇÃO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 48,
                      color: Colors.white,
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
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (live.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        live.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          live.authorName,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? AppTheme.errorRed
                                : AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHighlighted ? Icons.live_tv : Icons.play_arrow,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isHighlighted ? 'Assistir ao vivo' : 'Assistir',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorRed.withValues(alpha: 0.3 + (controller.value * 0.4)),
                blurRadius: 8 + (controller.value * 4),
                spreadRadius: controller.value * 2,
              ),
            ],
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: controller.value),
                      blurRadius: 4,
                      spreadRadius: controller.value * 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
