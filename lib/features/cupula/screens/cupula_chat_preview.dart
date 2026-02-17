import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_theme.dart';
import '../../../services/cupula_chat_service.dart';
import '../../../services/media_service.dart';
import '../../../utils/admin_helper.dart';
import '../widgets/cupula_widgets.dart';
import '../../../widgets/audio_player_widget.dart';
import '../../../widgets/audio_recorder_widget.dart';
import '../../../widgets/video_player_widget.dart';

// Neon green color constant for consistency
const Color _kNeonGreen = Color(0xFF00FF88);

class CupulaChatPreview extends StatefulWidget {
  const CupulaChatPreview({super.key});

  @override
  State<CupulaChatPreview> createState() => _CupulaChatPreviewState();
}

class _CupulaChatPreviewState extends State<CupulaChatPreview>
    with SingleTickerProviderStateMixin {
  final CupulaChatService _chatService = CupulaChatService();
  final MediaService _mediaService = MediaService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;
  late Stream<QuerySnapshot> _messagesStream;

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  Map<String, dynamic>? _replyingTo;
  bool _isRecordingAudio = false;

  final ValueNotifier<bool> _showMentionNotifier = ValueNotifier(false);
  final ValueNotifier<String> _mentionQueryNotifier = ValueNotifier('');
  List<Map<String, dynamic>> _mentionableUsers = [];
  List<Map<String, dynamic>> _mentionedUsers = [];

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getMessages();
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
    _messageController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    _showMentionNotifier.dispose();
    _mentionQueryNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _toggleAudioRecording() {
    setState(() {
      _isRecordingAudio = !_isRecordingAudio;
    });
  }

  Future<void> _loadMentionableUsers() async {
    final users = await _chatService.getMentionableUsers();
    setState(() {
      _mentionableUsers = users;
    });
  }

  void _onTextChanged(String text) {
    final cursorPos = _messageController.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      _showMentionNotifier.value = false;
      return;
    }

    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final query = textBeforeCursor.substring(lastAtIndex + 1);
      if (!query.contains(' ') && query.length < 20) {
        _showMentionNotifier.value = true;
        _mentionQueryNotifier.value = query.toLowerCase();
        if (_mentionableUsers.isEmpty) {
          _loadMentionableUsers();
        }
        return;
      }
    }
    _showMentionNotifier.value = false;
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;
    final lastAtIndex = text.substring(0, cursorPos).lastIndexOf('@');

    final displayName = user['displayName'] as String? ?? 'Usuário';
    final newText = '${text.substring(0, lastAtIndex)}@$displayName ${text.substring(cursorPos)}';

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: lastAtIndex + displayName.length + 2,
    );

    _showMentionNotifier.value = false;
    _mentionedUsers.add(user);
  }

  Future<void> _sendAudioMessage(dynamic audioData, int durationSeconds) async {
    debugPrint('🎤 _sendAudioMessage chamado. Tipo: ${audioData.runtimeType}, Duração: $durationSeconds');

    setState(() {
      _isRecordingAudio = false;
      _isUploading = true;
    });

    try {
      Uint8List audioBytes;

      if (audioData is Uint8List) {
        audioBytes = audioData;
        debugPrint('🎤 audioData já é Uint8List: ${audioBytes.length} bytes');
      } else if (audioData is String) {
        if (kIsWeb) {
          debugPrint('🎤 Web: URL de áudio: $audioData');
          final response = await http.get(Uri.parse(audioData));
          if (response.statusCode == 200) {
            audioBytes = response.bodyBytes;
            debugPrint('🎤 Web: áudio baixado: ${audioBytes.length} bytes');
          } else {
            throw Exception('Erro ao baixar áudio: ${response.statusCode}');
          }
        } else {
          final file = File(audioData);
          audioBytes = await file.readAsBytes();
          debugPrint('🎤 Arquivo lido: ${audioBytes.length} bytes');
        }
      } else {
        throw Exception('Tipo de áudio inválido: ${audioData.runtimeType}');
      }

      final audioUrl = await _mediaService.uploadAudio(
        audioBytes,
        _chatService.currentUser?.uid ?? 'unknown',
      );

      await _chatService.sendMessage(
        message: '',
        audioUrl: audioUrl,
        audioDurationSeconds: durationSeconds,
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('🎤 Erro ao enviar áudio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar áudio: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final videoBytes = await pickedFile.readAsBytes();
      debugPrint('🎥 Vídeo selecionado: ${videoBytes.length} bytes');

      final videoUrl = await _mediaService.uploadVideo(
        videoBytes,
        _chatService.currentUser?.uid ?? 'unknown',
      );

      await _chatService.sendMessage(
        message: '',
        videoUrl: videoUrl,
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('🎥 Erro ao enviar vídeo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar vídeo: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final imageToSend = _selectedImageBytes;
    final replyTo = _replyingTo;
    final mentions = List<Map<String, dynamic>>.from(_mentionedUsers);

    if (messageText.isEmpty && imageToSend == null) return;

    _messageController.clear();
    _showMentionNotifier.value = false;
    _mentionedUsers.clear();
    setState(() {
      _selectedImageBytes = null;
      _replyingTo = null;
      _isUploading = true;
    });

    try {
      String? imageUrl;

      if (imageToSend != null) {
        imageUrl = await _chatService.uploadImage(imageToSend);
      }

      debugPrint('Enviando mensagem: "$messageText", imageUrl: $imageUrl');

      await _chatService.sendMessage(
        message: messageText,
        imageUrl: imageUrl,
        replyToId: replyTo?['id'],
        replyToUserName: replyTo?['userName'],
        replyToMessage: replyTo?['message'],
        mentions: mentions,
      );

      debugPrint('Mensagem enviada com sucesso');

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      if (mounted) {
        if (e.toString().contains('bloqueado')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você foi bloqueado e não pode enviar mensagens'),
              backgroundColor: AppTheme.errorRed,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMessageOptions({
    required String messageId,
    required String messageUserId,
    required String message,
    required String userName,
    required bool isMe,
  }) {
    final isAdmin = AdminHelper.isCurrentUserAdmin();

    debugPrint('📋 _showMessageOptions chamado:');
    debugPrint('   messageId: $messageId');
    debugPrint('   messageUserId: $messageUserId');
    debugPrint('   userName: $userName');
    debugPrint('   isMe: $isMe');
    debugPrint('   isAdmin: $isAdmin');
    debugPrint('   Mostrar banir? ${isAdmin && !isMe}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: _kNeonGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              _buildReactionPicker(messageId),

              const Divider(
                color: Colors.white12,
                height: 1,
              ),
              const SizedBox(height: 8),

              // Responder
              _buildOptionTile(
                icon: Icons.reply_rounded,
                label: 'Responder',
                color: _kNeonGreen,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = {
                      'id': messageId,
                      'userName': userName,
                      'message': message,
                    };
                  });
                },
              ),

              // Copiar
              _buildOptionTile(
                icon: Icons.copy_rounded,
                label: 'Copiar texto',
                color: AppTheme.textSecondary,
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Texto copiado!'),
                      backgroundColor: _kNeonGreen.withValues(alpha: 0.8),
                    ),
                  );
                },
              ),

              // Editar (só minhas mensagens)
              if (isMe)
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Editar',
                  color: AppTheme.infoBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(messageId, message);
                  },
                ),

              // Deletar (minhas mensagens OU admin)
              if (isMe || isAdmin)
                _buildOptionTile(
                  icon: Icons.delete_rounded,
                  label: 'Deletar',
                  color: AppTheme.errorRed,
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteMessageWithConfirm(messageId, isAdmin && !isMe);
                  },
                ),

              // BANIR USUÁRIO (só admin, não pode banir a si mesmo)
              if (isAdmin && !isMe)
                _buildOptionTile(
                  icon: Icons.block_rounded,
                  label: 'Banir usuário',
                  color: AppTheme.errorRed,
                  onTap: () async {
                    Navigator.pop(context);
                    await _banUserWithConfirm(messageUserId, userName);
                  },
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionPicker(String messageId) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: emojis.map((emoji) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _chatService.toggleReaction(messageId, emoji);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _deleteMessageWithConfirm(String messageId, bool useAdminDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.errorRed.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Deletar mensagem',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Tem certeza que deseja deletar esta mensagem?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Deletar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (useAdminDelete) {
          await _chatService.deleteMessageAsAdmin(messageId);
        } else {
          await _chatService.deleteMessage(messageId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensagem deletada!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar: $e')),
          );
        }
      }
    }
  }

  Future<void> _banUserWithConfirm(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.errorRed.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Banir usuário',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Banir $userName? Ele não poderá mais enviar mensagens.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Banir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _chatService.banUser(userId, userName);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName foi banido'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(String messageId, String currentMessage) async {
    final controller = TextEditingController(text: currentMessage);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _kNeonGreen.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          'Editar mensagem',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Digite a nova mensagem',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _kNeonGreen.withValues(alpha: 0.5)),
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNeonGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await _chatService.editMessage(messageId, result.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensagem editada!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao editar: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (snapshot.hasError) {
                  return _buildError();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? '';
                    final currentUserId = _chatService.currentUser?.uid ?? '';
                    final isMe = userId == currentUserId && userId.isNotEmpty;

                    final currentTimestamp = data['createdAt'] as Timestamp?;
                    bool showDateSeparator = false;
                    if (currentTimestamp != null) {
                      final currentDate = currentTimestamp.toDate();
                      final currentDay = DateTime(currentDate.year, currentDate.month, currentDate.day);

                      if (index == messages.length - 1) {
                        showDateSeparator = true;
                      } else {
                        final nextData = messages[index + 1].data() as Map<String, dynamic>;
                        final nextTimestamp = nextData['createdAt'] as Timestamp?;
                        if (nextTimestamp != null) {
                          final nextDate = nextTimestamp.toDate();
                          final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
                          showDateSeparator = currentDay != nextDay;
                        } else {
                          showDateSeparator = true;
                        }
                      }
                    }

                    final messageBubble = TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index % 5) * 50),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _MessageBubble(
                        messageId: doc.id,
                        userId: userId,
                        userName: data['userName'] ?? 'Usuário',
                        userPhotoUrl: data['userPhotoUrl'] as String?,
                        message: data['message'] ?? '',
                        timestamp: currentTimestamp,
                        editedAt: data['editedAt'] as Timestamp?,
                        imageUrl: data['imageUrl'] as String?,
                        audioUrl: data['audioUrl'] as String?,
                        audioDurationSeconds: data['audioDurationSeconds'] as int?,
                        videoUrl: data['videoUrl'] as String?,
                        videoDurationSeconds: data['videoDurationSeconds'] as int?,
                        replyToUserName: data['replyToUserName'] as String?,
                        replyToMessage: data['replyToMessage'] as String?,
                        reactions: data['reactions'] as Map<String, dynamic>?,
                        currentUserId: currentUserId,
                        isAdmin: data['isAdmin'] ?? false,
                        isMe: isMe,
                        onLongPress: () => _showMessageOptions(
                          messageId: doc.id,
                          messageUserId: userId,
                          message: data['message'] ?? '',
                          userName: data['userName'] ?? 'Usuário',
                          isMe: isMe,
                        ),
                        onReaction: (emoji) => _chatService.toggleReaction(doc.id, emoji),
                      ),
                    );

                    if (showDateSeparator && currentTimestamp != null) {
                      return Column(
                        children: [
                          _buildDateSeparator(currentTimestamp.toDate()),
                          messageBubble,
                        ],
                      );
                    }

                    return messageBubble;
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
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
              // Icon container with glow
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
                  Icons.forum_rounded,
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
                      'Chat Exclusivo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Membros da Cúpula',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kNeonGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _kNeonGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _kNeonGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 14,
                        color: _kNeonGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Respondendo a ${_replyingTo!['userName']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _kNeonGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _replyingTo!['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _replyingTo = null;
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.errorRed,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentionList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showMentionNotifier,
      builder: (context, showMention, _) {
        if (!showMention) return const SizedBox.shrink();

        return ValueListenableBuilder<String>(
          valueListenable: _mentionQueryNotifier,
          builder: (context, query, _) {
            final filteredUsers = _mentionableUsers.where((user) {
              final name = (user['displayName'] as String? ?? '').toLowerCase();
              return name.contains(query);
            }).toList();

            if (filteredUsers.isEmpty) return const SizedBox.shrink();

            return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kNeonGreen.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final displayName = user['displayName'] as String? ?? 'Usuário';
          final photoUrl = user['photoURL'] as String?;

          return InkWell(
            onTap: () => _insertMention(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(photoUrl),
                      backgroundColor: AppTheme.cardMedium,
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kNeonGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: _kNeonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.verified_rounded,
                    color: _kNeonGreen.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(
            color: _kNeonGreen.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_isRecordingAudio) ...[
              AudioRecorderWidget(
                onRecordingComplete: _sendAudioMessage,
                onCancel: () {
                  setState(() {
                    _isRecordingAudio = false;
                  });
                },
              ),
            ] else ...[
              _buildMentionList(),
              _buildReplyPreview(),
              if (_selectedImageBytes != null) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kNeonGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.image_rounded,
                                  color: _kNeonGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Imagem selecionada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Escreva uma legenda abaixo',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _removeSelectedImage,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.errorRed,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Input de mensagem
            Row(
              children: [
                // Botão de imagem
                GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kNeonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _kNeonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: _isUploading
                          ? AppTheme.textTertiary
                          : _kNeonGreen,
                      size: 22,
                    ),
                  ),
                ),
                if (AdminHelper.isCurrentUserAdmin()) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isUploading ? null : _toggleAudioRecording,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kNeonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kNeonGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        color: _isUploading
                            ? AppTheme.textTertiary
                            : _kNeonGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndSendVideo,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kNeonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kNeonGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: _isUploading
                            ? AppTheme.textTertiary
                            : _kNeonGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _kNeonGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      enabled: !_isUploading,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: _isUploading
                            ? 'Enviando...'
                            : _selectedImageBytes != null
                                ? 'Adicionar legenda (opcional)...'
                                : 'Digite sua mensagem...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Botão enviar
                GestureDetector(
                  onTap: _isUploading ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isUploading
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _kNeonGreen,
                                _kNeonGreen.withValues(alpha: 0.8),
                              ],
                            ),
                      color: _isUploading ? AppTheme.textTertiary : null,
                      shape: BoxShape.circle,
                      boxShadow: _isUploading
                          ? null
                          : [
                              BoxShadow(
                                color: _kNeonGreen.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: _isUploading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Hoje';
    } else if (messageDate == yesterday) {
      dateText = 'Ontem';
    } else {
      const months = [
        '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      dateText = '${date.day} de ${months[date.month]} de ${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22282F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              color: Color(0xFF9ca3af),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoader(width: 100, height: 14),
                      SizedBox(height: 8),
                      SkeletonLoader(width: double.infinity, height: 50),
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

  Widget _buildError() {
    return Center(
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
            'Erro ao carregar mensagens',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente novamente mais tarde',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: _kNeonGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma mensagem ainda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seja o primeiro a enviar uma mensagem!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _kNeonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kNeonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kNeonGreen,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Use o campo abaixo',
                  style: TextStyle(
                    color: _kNeonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String message;
  final Timestamp? timestamp;
  final Timestamp? editedAt;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationSeconds;
  final String? videoUrl;
  final int? videoDurationSeconds;
  final String? replyToUserName;
  final String? replyToMessage;
  final Map<String, dynamic>? reactions;
  final String? currentUserId;
  final bool isAdmin;
  final bool isMe;
  final VoidCallback onLongPress;
  final Function(String emoji) onReaction;

  const _MessageBubble({
    required this.messageId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    this.timestamp,
    this.editedAt,
    this.imageUrl,
    this.audioUrl,
    this.audioDurationSeconds,
    this.videoUrl,
    this.videoDurationSeconds,
    this.replyToUserName,
    this.replyToMessage,
    this.reactions,
    this.currentUserId,
    required this.isAdmin,
    required this.isMe,
    required this.onLongPress,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp != null
        ? DateFormat('HH:mm').format(timestamp!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with glow for admin
          Container(
            decoration: isAdmin
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kNeonGreen.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  )
                : null,
            child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(userPhotoUrl!),
                    backgroundColor: isAdmin ? _kNeonGreen : AppTheme.cardMedium,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: isAdmin
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _kNeonGreen,
                                _kNeonGreen.withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isAdmin ? null : AppTheme.cardMedium,
                      shape: BoxShape.circle,
                      border: isMe && !isAdmin
                          ? Border.all(
                              color: _kNeonGreen.withValues(alpha: 0.5),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isAdmin ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Conteúdo da mensagem
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + Badge + Hora
                Row(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? _kNeonGreen : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _kNeonGreen,
                              _kNeonGreen.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: _kNeonGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (isMe && !isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kNeonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VOCÊ',
                          style: TextStyle(
                            color: _kNeonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Mensagem
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _kNeonGreen.withValues(alpha: 0.15),
                                _kNeonGreen.withValues(alpha: 0.05),
                              ],
                            )
                          : null,
                      color: isMe ? null : AppTheme.cardMedium,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe
                          ? Border.all(
                              color: _kNeonGreen.withValues(alpha: 0.3),
                            )
                          : isAdmin
                              ? Border.all(
                                  color: _kNeonGreen.withValues(alpha: 0.2),
                                )
                              : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview do reply (se existir)
                        if (replyToMessage != null && replyToMessage!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: _kNeonGreen,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyToUserName ?? 'Usuário',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _kNeonGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  replyToMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _openFullscreenImage(context, imageUrl!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl!,
                                width: 220,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 220,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _kNeonGreen,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 220,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: AppTheme.textTertiary,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (message.isNotEmpty) const SizedBox(height: 10),
                        ],
                        if (audioUrl != null && audioUrl!.isNotEmpty) ...[
                          AudioPlayerWidget(
                            audioUrl: audioUrl!,
                            durationSeconds: audioDurationSeconds ?? 0,
                          ),
                          if (message.isNotEmpty) const SizedBox(height: 10),
                        ],
                        if (videoUrl != null && videoUrl!.isNotEmpty) ...[
                          VideoPlayerWidget(
                            videoUrl: videoUrl!,
                            durationSeconds: videoDurationSeconds,
                          ),
                          if (message.isNotEmpty) const SizedBox(height: 10),
                        ],
                        if (message.isNotEmpty)
                          _buildMessageText(message),
                        if (editedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '(editada)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildReactions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text) {
    final combinedRegex = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+)|(@\w+)',
    );
    final matches = combinedRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    const normalStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.4,
    );

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: normalStyle,
        ));
      }

      final urlMatch = match.group(1);
      final mentionMatch = match.group(2);

      if (urlMatch != null) {
        final url = urlMatch.startsWith('www.') ? 'https://$urlMatch' : urlMatch;
        spans.add(TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: _kNeonGreen,
            fontSize: 14,
            height: 1.4,
            decoration: TextDecoration.underline,
            decorationColor: _kNeonGreen,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
        ));
      } else if (mentionMatch != null) {
        spans.add(TextSpan(
          text: mentionMatch,
          style: const TextStyle(
            color: _kNeonGreen,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: normalStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _openFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kNeonGreen,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactions() {
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: reactions!.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value as List<dynamic>? ?? [];
          if (users.isEmpty) return const SizedBox.shrink();

          final hasReacted = currentUserId != null && users.contains(currentUserId);

          return GestureDetector(
            onTap: () => onReaction(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReacted
                    ? _kNeonGreen.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasReacted
                      ? _kNeonGreen.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasReacted ? _kNeonGreen : Colors.white.withValues(alpha: 0.7),
                      fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
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
}
