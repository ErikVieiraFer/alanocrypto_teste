import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../theme/app_theme.dart';
import '../services/cupula_lives_service.dart';
import '../services/cupula_live_chat_service.dart';

class CupulaLiveWatchScreen extends StatefulWidget {
  final CupulaLive live;

  const CupulaLiveWatchScreen({super.key, required this.live});

  @override
  State<CupulaLiveWatchScreen> createState() => _CupulaLiveWatchScreenState();
}

class _CupulaLiveWatchScreenState extends State<CupulaLiveWatchScreen> {
  late YoutubePlayerController _playerController;
  final CupulaLiveChatService _chatService = CupulaLiveChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPanel = false;
  bool _showChat = true;

  static const List<String> _quickEmojis = [
    '🔥', '🚀', '👏', '😂', '❤️', '💰', '📈', '📉',
    '👍', '👎', '🎯', '💪', '🙏', '😎', '🤔', '😮',
  ];

  static const List<String> _quickReactions = ['🔥', '🚀', '👏', '😂', '❤️'];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final videoId = widget.live.youtubeVideoId;
    debugPrint('🎬 Inicializando player com videoId: $videoId');

    _playerController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
        loop: false,
        enableCaption: false,
        playsInline: true,
      ),
    );
  }

  @override
  void dispose() {
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

  void _showReactionMenu(LiveChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
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
                  color: AppTheme.textPrimary,
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
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                            : AppTheme.cardMedium,
                        borderRadius: BorderRadius.circular(12),
                        border: hasReacted
                            ? Border.all(color: AppTheme.primaryGreen)
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
            ],
          ),
        ),
      ),
    );
  }

  double _getPlayerHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (kIsWeb) {
      final maxHeight = screenHeight * 0.35;
      final calculatedHeight = screenWidth * 9 / 16;
      return calculatedHeight > maxHeight ? maxHeight : calculatedHeight;
    } else {
      return screenWidth * 9 / 16 * 0.85;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerHeight = _getPlayerHeight(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111418),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'AO VIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: playerHeight,
            child: YoutubePlayer(
              controller: _playerController,
              aspectRatio: 16 / 9,
            ),
          ),
          _buildChatHeader(),
          if (_showChat) ...[
            Expanded(
              child: _buildChatMessages(),
            ),
            if (_showEmojiPanel) _buildEmojiPanel(),
            _buildMessageInput(),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chat minimizado',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showChat = true),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Mostrar chat'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
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

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: AppTheme.primaryGreen, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Chat ao Vivo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: _chatService.getViewersCount(widget.live.id),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showChat = !_showChat),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showChat
                    ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                    : AppTheme.cardMedium,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _showChat ? Icons.visibility : Icons.visibility_off,
                color: _showChat ? AppTheme.primaryGreen : AppTheme.textSecondary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<List<LiveChatMessage>>(
      stream: _chatService.getMessages(widget.live.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erro ao carregar chat',
              style: TextStyle(color: AppTheme.textSecondary),
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
                  size: 40,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seja o primeiro a comentar!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients &&
              _scrollController.position.pixels == _scrollController.position.maxScrollExtent - 100) {
            _scrollToBottom();
          }
        });

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: kIsWeb,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
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
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: _quickEmojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(_quickEmojis[index]),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardMedium,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _quickEmojis[index],
                  style: const TextStyle(fontSize: 18),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showEmojiPanel = !_showEmojiPanel;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF111418),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onTap: () {
                  if (_showEmojiPanel) {
                    setState(() {
                      _showEmojiPanel = false;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: isMe
                ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (message.oderPhoto != null && message.oderPhoto!.isNotEmpty)
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(message.oderPhoto!),
                    )
                  else
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        message.oderName.isNotEmpty
                            ? message.oderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.oderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isMe ? AppTheme.primaryGreen : AppTheme.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: message.reactions.entries.map((entry) {
                      if (entry.value.isEmpty) return const SizedBox.shrink();
                      final hasReacted = entry.value.contains(currentUserId);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : AppTheme.cardMedium,
                          borderRadius: BorderRadius.circular(10),
                          border: hasReacted
                              ? Border.all(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${entry.value.length}',
                              style: TextStyle(
                                fontSize: 9,
                                color: hasReacted
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textSecondary,
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
