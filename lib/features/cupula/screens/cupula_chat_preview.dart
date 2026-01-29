import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../services/cupula_chat_service.dart';
import '../../../utils/admin_helper.dart';
import '../widgets/cupula_widgets.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  File? _selectedImage;
  bool _isUploading = false;
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _selectedImage = File(pickedFile.path);
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
      _selectedImage = null;
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    final imageToSend = _selectedImage;
    final replyTo = _replyingTo;

    if (messageText.isEmpty && imageToSend == null) return;

    _messageController.clear();
    setState(() {
      _selectedImage = null;
      _replyingTo = null;
      _isUploading = true;
    });

    try {
      String? imageUrl;

      if (imageToSend != null) {
        imageUrl = await _chatService.uploadImage(imageToSend);
      }

      await _chatService.sendMessage(
        message: messageText,
        imageUrl: imageUrl,
        replyToId: replyTo?['id'],
        replyToUserName: replyTo?['userName'],
        replyToMessage: replyTo?['message'],
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
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
              const SizedBox(height: 16),

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
              stream: _chatService.getMessages(),
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? '';
                    final currentUserId = _chatService.currentUser?.uid ?? '';
                    final isMe = userId == currentUserId && userId.isNotEmpty;

                    return TweenAnimationBuilder<double>(
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
                        timestamp: data['createdAt'] as Timestamp?,
                        editedAt: data['editedAt'] as Timestamp?,
                        imageUrl: data['imageUrl'] as String?,
                        replyToUserName: data['replyToUserName'] as String?,
                        replyToMessage: data['replyToMessage'] as String?,
                        isAdmin: data['isAdmin'] ?? false,
                        isMe: isMe,
                        onLongPress: () => _showMessageOptions(
                          messageId: doc.id,
                          messageUserId: userId,
                          message: data['message'] ?? '',
                          userName: data['userName'] ?? 'Usuário',
                          isMe: isMe,
                        ),
                      ),
                    );
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
              // Online indicator chip
              StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(),
                builder: (context, snapshot) {
                  final memberCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kNeonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kNeonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _kNeonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kNeonGreen.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$memberCount msgs',
                          style: const TextStyle(
                            color: _kNeonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
            _buildReplyPreview(),
            // Preview da imagem selecionada
            if (_selectedImage != null) ...[
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
                        child: Image.file(
                          _selectedImage!,
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
                            const Text(
                              'Imagem selecionada',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pronta para enviar',
                              style: TextStyle(
                                color: _kNeonGreen.withValues(alpha: 0.8),
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
                const SizedBox(width: 10),
                // TextField
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
                      decoration: InputDecoration(
                        hintText: _isUploading
                            ? 'Enviando...'
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
  final String? replyToUserName;
  final String? replyToMessage;
  final bool isAdmin;
  final bool isMe;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.messageId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    this.timestamp,
    this.editedAt,
    this.imageUrl,
    this.replyToUserName,
    this.replyToMessage,
    required this.isAdmin,
    required this.isMe,
    required this.onLongPress,
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
                        // Imagem (se existir)
                        if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                          ClipRRect(
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
                          if (message.isNotEmpty) const SizedBox(height: 10),
                        ],
                        // Texto (se existir)
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
