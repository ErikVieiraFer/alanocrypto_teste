import 'package:flutter/material.dart';
import '../widgets/intro_video_section.dart';
import '../widgets/news_section.dart';
import '../widgets/market_list_card.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final bool isDrawerOpen;
  final bool isDialogOpen;

  const HomeScreen({
    super.key,
    this.isDrawerOpen = false,
    this.isDialogOpen = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: AppTheme.primaryGreen,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32.0 : AppTheme.mobileHorizontalPadding,
            vertical: AppTheme.mobileVerticalPadding,
          ),
          children: [
            if (isDesktop)
              _buildDesktopLayout()
            else
              _buildMobileLayout(),
            const SizedBox(height: AppTheme.mobileSectionSpacing),
            RepaintBoundary(
              child: const NewsSection(),
            ),
            const SizedBox(height: AppTheme.bottomSafeArea),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        IntroVideoSection(
          isDrawerOpen: widget.isDrawerOpen,
          isDialogOpen: widget.isDialogOpen,
        ),
        const SizedBox(height: AppTheme.mobileSectionSpacing),
        RepaintBoundary(
          child: const MarketListCard(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: IntroVideoSection(
            isDrawerOpen: widget.isDrawerOpen,
            isDialogOpen: widget.isDialogOpen,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: RepaintBoundary(
            child: const MarketListCard(),
          ),
        ),
      ],
    );
  }
}
