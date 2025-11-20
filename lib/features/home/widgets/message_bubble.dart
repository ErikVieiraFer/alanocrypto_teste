import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/message_model.dart';
import '../../../theme/app_theme.dart';
import '../../profile/screens/profile_screen.dart';
import 'full_screen_image_view.dart';

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
                            ? const Color.fromRGBO(79, 211, 101, 0.15)
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
                            _buildImage(context),
                            const SizedBox(height: 8),
                          ],

                          // Texto da mensagem (BRANCO e MAIOR)
                          if (message.text.isNotEmpty) ...[
                            _buildMessageText(context),
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
                                style: const TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 0.5),
                                  fontSize: 12,
                                ),
                              ),
                              if (message.isEdited) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(editado)',
                                  style: const TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 0.5),
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

    // Se não tem foto ou foto é vazia, mostrar inicial
    if (photoUrl == null || photoUrl.isEmpty) {
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
        color: const Color.fromRGBO(0, 0, 0, 0.15),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppTheme.accentGreen, width: 3)),
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
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromRGBO(255, 255, 255, 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = message.imageUrl!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => FullScreenImageView(
              imageUrl: message.imageUrl!,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
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
        ),
      ),
    );
  }

  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }

  Widget _buildMessageText(BuildContext context) {
    final List<TextSpan> spans = [];
    int currentPosition = 0;

    // Coletar todas as marcações (menções e URLs)
    final List<_TextMarker> markers = [];

    // Adicionar menções
    for (final mention in message.mentions) {
      markers.add(_TextMarker(
        start: mention.startIndex,
        end: mention.startIndex + mention.length,
        type: _MarkerType.mention,
        data: mention,
      ));
    }

    // Adicionar URLs
    final urlMatches = _urlRegex.allMatches(message.text);
    for (final match in urlMatches) {
      // Verificar se a URL não está dentro de uma menção
      bool insideMention = markers.any((m) =>
          m.type == _MarkerType.mention &&
          match.start >= m.start &&
          match.end <= m.end);

      if (!insideMention) {
        markers.add(_TextMarker(
          start: match.start,
          end: match.end,
          type: _MarkerType.url,
          data: match.group(0),
        ));
      }
    }

    // Ordenar por posição inicial
    markers.sort((a, b) => a.start.compareTo(b.start));

    // Se não há marcações, retornar texto simples
    if (markers.isEmpty) {
      return Text(
        message.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.4,
        ),
      );
    }

    // Construir spans
    for (final marker in markers) {
      // Texto antes da marcação
      if (marker.start > currentPosition) {
        spans.add(TextSpan(
          text: message.text.substring(currentPosition, marker.start),
        ));
      }

      // Marcação
      if (marker.type == _MarkerType.mention) {
        final mention = marker.data as Mention;
        spans.add(
          TextSpan(
            text: message.text.substring(marker.start, marker.end),
            style: const TextStyle(
              color: Color.fromRGBO(74, 158, 255, 1),
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()..onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: mention.userId),
                ),
              );
            },
          ),
        );
      } else if (marker.type == _MarkerType.url) {
        final url = marker.data as String;
        spans.add(
          TextSpan(
            text: url,
            style: const TextStyle(
              color: Color.fromRGBO(74, 158, 255, 1),
              decoration: TextDecoration.underline,
              decorationColor: Color.fromRGBO(74, 158, 255, 1),
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
          ),
        );
      }

      currentPosition = marker.end;
    }

    // Texto após a última marcação
    if (currentPosition < message.text.length) {
      spans.add(TextSpan(
        text: message.text.substring(currentPosition),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.4,
        ),
        children: spans,
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
                color: const Color.fromRGBO(79, 211, 101, 0.2),
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  top: BorderSide(color: Color.fromRGBO(79, 211, 101, 0.5), width: 1.5),
                  bottom: BorderSide(color: Color.fromRGBO(79, 211, 101, 0.5), width: 1.5),
                  left: BorderSide(color: Color.fromRGBO(79, 211, 101, 0.5), width: 1.5),
                  right: BorderSide(color: Color.fromRGBO(79, 211, 101, 0.5), width: 1.5),
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

// Classes auxiliares para marcação de texto
enum _MarkerType { mention, url }

class _TextMarker {
  final int start;
  final int end;
  final _MarkerType type;
  final dynamic data;

  _TextMarker({
    required this.start,
    required this.end,
    required this.type,
    required this.data,
  });
}
