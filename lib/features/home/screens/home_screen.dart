import 'package:flutter/material.dart';
import '../widgets/intro_video_section.dart';
import '../widgets/crypto_market_section.dart';
import '../widgets/chats_section.dart';
import '../widgets/news_section.dart';

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
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: const Color.fromRGBO(76, 175, 80, 1),
      child: ListView(
        controller: _scrollController,
        children: const [
          SizedBox(height: 16),
          IntroVideoSection(),
          SizedBox(height: 24),
          CryptoMarketSection(),
          SizedBox(height: 24),
          ChatsSection(),
          SizedBox(height: 24),
          NewsSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
