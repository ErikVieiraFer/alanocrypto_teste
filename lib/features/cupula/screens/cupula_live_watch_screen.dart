import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../theme/app_theme.dart';
import '../services/cupula_lives_service.dart';
import '../services/cupula_live_chat_service.dart';

const Color _kNeonGreen = Color(0xFF00FF88);

class CupulaLiveWatchScreen extends StatefulWidget {
  final CupulaLive live;

  const CupulaLiveWatchScreen({super.key, required this.live});

  @override
  State<CupulaLiveWatchScreen> createState() => _CupulaLiveWatchScreenState();
}

class _CupulaLiveWatchScreenState extends State<CupulaLiveWatchScreen> {
  final GlobalKey _playerContainerKey = GlobalKey();
  late YoutubePlayerController _playerController;
  final CupulaLiveChatService _chatService = CupulaLiveChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPanel = false;
  bool _isChatVisible = true;
  bool _isFullscreen = false;
  bool _isLandscape = false;
  bool _showFullscreenBar = true;

  late Stream<List<LiveChatMessage>> _messagesStream;
  late Stream<int> _viewersStream;

  late Widget _cachedPlayer;

  static const List<String> _quickEmojis = [
    '🔥', '🚀', '👏', '😂', '❤️', '💰', '📈', '📉',
    '👍', '👎', '🎯', '💪', '🙏', '😎', '🤔', '😮',
  ];

  static const List<String> _quickReactions = ['🔥', '🚀', '👏', '😂', '❤️'];

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _messagesStream = _chatService.getMessages(widget.live.id);
    _viewersStream = _chatService.getViewersCount(widget.live.id);
  }

  void _initPlayer() {
    final videoId = widget.live.youtubeVideoId;
    _playerController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: false,
        showControls: true,
        mute: false,
        loop: false,
        enableCaption: false,
        playsInline: true,
      ),
    );

    _cachedPlayer = YoutubePlayer(
      key: _playerContainerKey,
      controller: _playerController,
      aspectRatio: 16 / 9,
    );
  }

  @override
  void dispose() {
    _exitFullscreen();
    _playerController.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(widget.live.id, text);
    _messageController.clear();
    setState(() {
      _showEmojiPanel = false;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _insertEmoji(String emoji) {
    _messageController.text += emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _enterFullscreen() async {
    setState(() => _isFullscreen = true);
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _exitFullscreen() async {
    if (_isFullscreen) {
      setState(() => _isFullscreen = false);
      if (!kIsWeb) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  void _showReactionMenu(LiveChatMessage message) {
    final isMyMessage = message.oderId == _chatService.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1f25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reagir à mensagem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _quickReactions.map((emoji) {
                  final hasReacted = message.hasReacted(
                    emoji,
                    _chatService.currentUser?.uid ?? '',
                  );
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _chatService.toggleReaction(
                        widget.live.id,
                        message.id,
                        emoji,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? _kNeonGreen.withValues(alpha: 0.2)
                            : const Color(0xFF22282F),
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted
                            ? Border.all(color: _kNeonGreen)
                            : null,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (isMyMessage) ...[
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF333840)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(message);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Excluir mensagem',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(LiveChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir mensagem?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await _chatService.deleteMessage(
                widget.live.id,
                message.id,
              );
              if (mounted && success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Mensagem excluída'),
                    backgroundColor: _kNeonGreen,
                  ),
                );
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenLayout();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildFullscreenLayout() {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          if (_showFullscreenBar)
            Container(
              color: const Color(0xFF111418),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                left: 12,
                right: 12,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isLandscape = !_isLandscape),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22282F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333840)),
                      ),
                      child: Icon(
                        _isLandscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _isLandscape = false;
                      _exitFullscreen();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22282F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333840)),
                      ),
                      child: const Icon(
                        Icons.fullscreen_exit,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showFullscreenBar = false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22282F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333840)),
                      ),
                      child: const Icon(
                        Icons.visibility_off,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showFullscreenBar = true),
              child: Container(
                color: Colors.black,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  right: 12,
                  bottom: 4,
                ),
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLandscape
                ? Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: SizedBox(
                        width: screenSize.height,
                        height: screenSize.width,
                        child: _cachedPlayer,
                      ),
                    ),
                  )
                : Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _cachedPlayer,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _cachedPlayer,
            ),
          ),
          _buildControlsBar(),
          if (_isChatVisible) ...[
            Expanded(child: _buildChat()),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 48,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Toque no vídeo para tela cheia',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _isChatVisible = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22282F),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _kNeonGreen.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble, color: _kNeonGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mostrar chat',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          Expanded(
            flex: _isChatVisible ? 7 : 10,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kNeonGreen.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _cachedPlayer,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.fullscreen,
                        label: 'Tela cheia',
                        onTap: _enterFullscreen,
                      ),
                      const SizedBox(width: 12),
                      _buildControlButton(
                        icon: _isChatVisible ? Icons.visibility_off : Icons.chat_bubble,
                        label: _isChatVisible ? 'Ocultar chat' : 'Mostrar chat',
                        onTap: () => setState(() => _isChatVisible = !_isChatVisible),
                        isActive: !_isChatVisible,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isChatVisible)
            Container(
              width: 360,
              decoration: const BoxDecoration(
                color: Color(0xFF1a1f25),
                border: Border(
                  left: BorderSide(color: Color(0xFF22282F), width: 1),
                ),
              ),
              child: _buildChat(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111418),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.live.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (widget.live.isLive)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
          ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111418),
        border: Border(
          bottom: BorderSide(color: Color(0xFF22282F)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<int>(
            stream: _viewersStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Row(
                children: [
                  const Icon(Icons.people, color: Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$count assistindo',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              );
            },
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _enterFullscreen,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22282F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF333840)),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isChatVisible = !_isChatVisible),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isChatVisible
                        ? _kNeonGreen.withValues(alpha: 0.15)
                        : const Color(0xFF22282F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isChatVisible
                          ? _kNeonGreen.withValues(alpha: 0.4)
                          : const Color(0xFF333840),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isChatVisible ? Icons.visibility_off : Icons.chat_bubble,
                        color: _isChatVisible ? _kNeonGreen : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isChatVisible ? 'Ocultar chat' : 'Mostrar chat',
                        style: TextStyle(
                          color: _isChatVisible ? _kNeonGreen : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? _kNeonGreen.withValues(alpha: 0.15)
                : const Color(0xFF22282F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? _kNeonGreen.withValues(alpha: 0.4)
                  : const Color(0xFF333840),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? _kNeonGreen : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _kNeonGreen : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF22282F),
            border: Border(
              bottom: BorderSide(color: Color(0xFF333840)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble, color: _kNeonGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Chat ao Vivo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StreamBuilder<int>(
                stream: _viewersStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildChatMessages()),
        if (_showEmojiPanel) _buildEmojiPanel(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<List<LiveChatMessage>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kNeonGreen),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erro ao carregar chat',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Seja o primeiro a comentar!',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: kIsWeb,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _ChatMessageBubble(
                message: messages[index],
                currentUserId: _chatService.currentUser?.uid ?? '',
                onLongPress: () => _showReactionMenu(messages[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmojiPanel() {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1f25),
        border: Border(
          top: BorderSide(color: Color(0xFF333840)),
        ),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _quickEmojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(_quickEmojis[index]),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF22282F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _quickEmojis[index],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1f25),
        border: Border(
          top: BorderSide(color: Color(0xFF333840)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showEmojiPanel = !_showEmojiPanel),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _showEmojiPanel
                      ? _kNeonGreen.withValues(alpha: 0.15)
                      : const Color(0xFF22282F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: _showEmojiPanel ? _kNeonGreen : Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF22282F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onTap: () {
                    if (_showEmojiPanel) {
                      setState(() => _showEmojiPanel = false);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kNeonGreen,
                      _kNeonGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kNeonGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final LiveChatMessage message;
  final String currentUserId;
  final VoidCallback onLongPress;

  const _ChatMessageBubble({
    required this.message,
    required this.currentUserId,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.oderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? _kNeonGreen.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: isMe
                ? Border.all(color: _kNeonGreen.withValues(alpha: 0.25))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (message.oderPhoto != null && message.oderPhoto!.isNotEmpty)
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(message.oderPhoto!),
                    )
                  else
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _kNeonGreen,
                      child: Text(
                        message.oderName.isNotEmpty
                            ? message.oderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.oderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMe ? _kNeonGreen : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: message.reactions.entries.map((entry) {
                      if (entry.value.isEmpty) return const SizedBox.shrink();
                      final hasReacted = entry.value.contains(currentUserId);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? _kNeonGreen.withValues(alpha: 0.2)
                              : const Color(0xFF22282F),
                          borderRadius: BorderRadius.circular(12),
                          border: hasReacted
                              ? Border.all(color: _kNeonGreen.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.value.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: hasReacted ? _kNeonGreen : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
