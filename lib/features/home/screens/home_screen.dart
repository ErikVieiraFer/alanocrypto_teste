import 'package:flutter/material.dart';
import '../widgets/intro_video_section.dart';
import '../widgets/crypto_market_section.dart';
import '../widgets/news_section.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: AppTheme.primaryGreen,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.mobileHorizontalPadding,
            vertical: AppTheme.mobileVerticalPadding,
          ),
          children: const [
            IntroVideoSection(),
            SizedBox(height: AppTheme.mobileSectionSpacing),
            CryptoMarketSection(),
            SizedBox(height: AppTheme.mobileSectionSpacing),
            NewsSection(),
            SizedBox(height: AppTheme.bottomSafeArea),
          ],
        ),
      ),
    );
  }
}
