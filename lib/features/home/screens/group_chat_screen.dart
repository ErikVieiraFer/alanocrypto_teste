import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/message_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/notification_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../../profile/screens/profile_screen.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Message? _replyToMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text, PickedImageFile? image) async {
    if (_currentUser == null) return;

    String? imageUrl;

    try {
      if (image != null && image.hasData) {
        imageUrl = await _chatService.uploadMessageImage(image, _currentUser!.uid);
      }

      final originalMessage = _replyToMessage;

      await _chatService.sendMessage(
        text: text,
        userId: _currentUser!.uid,
        userName: _currentUser!.displayName ?? 'Usuário',
        userPhotoUrl: _currentUser!.photoURL,
        imageUrl: imageUrl,
        replyToId: originalMessage?.id,
        replyToText: originalMessage?.text,
        replyToUserName: originalMessage?.userName,
      );

      // Criar notificação se for uma resposta para a mensagem de outra pessoa
      if (originalMessage != null && originalMessage.userId != _currentUser!.uid) {
        await _notificationService.createNotification(
          userId: originalMessage.userId, // Notifica o autor da mensagem original
          type: NotificationType.chatReply,
          title: '${_currentUser!.displayName} respondeu à sua mensagem',
          content: text,
          relatedId: _currentUser!.uid, // ID do usuário que respondeu
        );
      }

      setState(() {
        _replyToMessage = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    }
  }

  void _showMessageOptions(Message message) {
    final isMyMessage = message.userId == _currentUser?.uid;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions),
              title: const Text('Reagir'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessage = message;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar texto'),
              onTap: () {
                Navigator.pop(context);
                // Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado')),
                );
              },
            ),
            if (!isMyMessage)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: message.userId),
                    ),
                  );
                },
              ),
            if (isMyMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Deletar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(Message message) {
    final emojis = ['👍', '❤️', '😂', '🔥', '💯', '🚀'];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 1,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            final emoji = emojis[index];
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addReaction(message, emoji);
              },
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addReaction(Message message, String emoji) async {
    if (_currentUser == null) return;

    try {
      final userReactions = message.reactions[emoji] ?? [];
      if (userReactions.contains(_currentUser!.uid)) {
        await _chatService.removeReaction(message.id, emoji, _currentUser!.uid);
      } else {
        await _chatService.addReaction(message.id, emoji, _currentUser!.uid);

        // Criar notificação se não for a sua própria mensagem
        if (message.userId != _currentUser!.uid) {
          await _notificationService.createNotification(
            userId: message.userId, // Notifica o autor da mensagem
            type: NotificationType.chatReaction,
            title: '${_currentUser!.displayName} reagiu à sua mensagem',
            content: emoji,
            relatedId: message.id, // ID da mensagem que recebeu a reação
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar reação: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    if (_currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar mensagem'),
        content: const Text('Tem certeza que deseja deletar esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteMessage(message.id, _currentUser!.uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar mensagem: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(Message message) async {
    final controller = TextEditingController(text: message.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensagem'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite a nova mensagem',
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && _currentUser != null) {
      try {
        await _chatService.editMessage(message.id, result.trim(), _currentUser!.uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao editar mensagem: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar mensagens: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma mensagem ainda.\nSeja o primeiro a enviar!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.userId == _currentUser?.uid;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      onLongPress: () => _showMessageOptions(message),
                      onSwipe: () {
                        setState(() {
                          _replyToMessage = message;
                        });
                      },
                      onReactionTap: (emoji) => _addReaction(message, emoji),
                      onUserTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: message.userId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        MessageInput(
          onSend: _sendMessage,
          replyToUserName: _replyToMessage?.userName,
          replyToText: _replyToMessage?.text,
          onCancelReply: () {
            setState(() {
              _replyToMessage = null;
            });
          },
        ),
      ],
    );
  }
}
