import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/message_model.dart';
import '../../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onLongPress;
  final VoidCallback onSwipe;
  final Function(String emoji) onReactionTap;
  final VoidCallback? onUserTap;
  final String? currentUserPhotoUrl; // Foto atual do usuário (atualizada)

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.onSwipe,
    required this.onReactionTap,
    this.onUserTap,
    this.currentUserPhotoUrl, // Foto atual tem prioridade
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onSwipe();
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // Avatar - esquerda para mensagens dos outros
            if (!isMe) ...[
              GestureDetector(onTap: onUserTap, child: _buildAvatar()),
              const SizedBox(width: 12),
            ],

            // Bubble da mensagem
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: onLongPress,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppTheme.accentGreen.withOpacity(0.15)
                            : AppTheme.inputBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isMe ? 20 : 4),
                          topRight: Radius.circular(isMe ? 4 : 20),
                          bottomLeft: const Radius.circular(20),
                          bottomRight: const Radius.circular(20),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome do remetente DENTRO da mensagem (só para outros)
                          if (!isMe) ...[
                            GestureDetector(
                              onTap: onUserTap,
                              child: Text(
                                message.userName,
                                style: const TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Seção de resposta (se existir)
                          if (message.replyToText != null) ...[
                            _buildReplySection(theme),
                            const SizedBox(height: 8),
                          ],

                          // Imagem (se existir)
                          if (message.imageUrl != null) ...[
                            _buildImage(),
                            const SizedBox(height: 8),
                          ],

                          // Texto da mensagem (BRANCO e MAIOR)
                          if (message.text.isNotEmpty) ...[
                            Text(
                              message.text,
                              style: const TextStyle(
                                color: Colors.white, // SEMPRE BRANCO
                                fontSize: 18, // MAIOR (era 15)
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Timestamp dentro do bubble
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              if (message.isEdited) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(editado)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reações abaixo do bubble
                  if (message.reactions.isNotEmpty) _buildReactions(theme),
                ],
              ),
            ),

            // Avatar - direita para minhas mensagens
            if (isMe) ...[const SizedBox(width: 12), _buildAvatar()],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Usar a foto atual (prioridade) ou a foto salva na mensagem
    final photoUrl = currentUserPhotoUrl ?? message.userPhotoUrl;

    // Debug: verificar URL da foto
    if (photoUrl != null && photoUrl.isNotEmpty) {
      print(
        '🖼️ MessageBubble - Tentando carregar foto: $photoUrl (${currentUserPhotoUrl != null ? "atualizada" : "da mensagem"})',
      );
    }

    // Se não tem foto ou foto é vazia, mostrar inicial
    if (photoUrl == null || photoUrl.isEmpty) {
      print(
        '⚠️ MessageBubble - Sem foto para ${message.userName}, mostrando inicial',
      );
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.accentGreen,
        child: Text(
          message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Tem foto - tentar carregar com tratamento de erro
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.accentGreen,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            print('❌ MessageBubble - Erro ao carregar foto: $error');
            return Text(
              message.userName.isNotEmpty
                  ? message.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReplySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.accentGreen, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToUserName ?? 'Usuário',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message.replyToText ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: message.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[700],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[700],
          child: const Icon(Icons.error, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildReactions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: message.reactions.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;
          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
