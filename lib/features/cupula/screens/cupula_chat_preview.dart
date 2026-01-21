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

class CupulaChatPreview extends StatefulWidget {
  const CupulaChatPreview({super.key});

  @override
  State<CupulaChatPreview> createState() => _CupulaChatPreviewState();
}

class _CupulaChatPreviewState extends State<CupulaChatPreview> {
  final CupulaChatService _chatService = CupulaChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;

  // Reply state
  Map<String, dynamic>? _replyingTo;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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

    // Validar se tem pelo menos texto ou imagem
    if (messageText.isEmpty && imageToSend == null) return;

    // Limpar input, imagem e reply imediatamente
    _messageController.clear();
    setState(() {
      _selectedImage = null;
      _replyingTo = null;
      _isUploading = true;
    });

    try {
      String? imageUrl;

      // Upload da imagem se existir
      if (imageToSend != null) {
        imageUrl = await _chatService.uploadImage(imageToSend);
      }

      // Enviar mensagem
      await _chatService.sendMessage(
        message: messageText,
        imageUrl: imageUrl,
        replyToId: replyTo?['id'],
        replyToUserName: replyTo?['userName'],
        replyToMessage: replyTo?['message'],
      );

      // Scroll para o final após enviar
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
        // Usuário banido
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

    // DEBUG: Verificar valores
    debugPrint('📋 _showMessageOptions chamado:');
    debugPrint('   messageId: $messageId');
    debugPrint('   messageUserId: $messageUserId');
    debugPrint('   userName: $userName');
    debugPrint('   isMe: $isMe');
    debugPrint('   isAdmin: $isAdmin');
    debugPrint('   Mostrar banir? ${isAdmin && !isMe}');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Responder (todos)
            ListTile(
              leading: const Icon(Icons.reply, color: AppTheme.primaryGreen),
              title: const Text(
                'Responder',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
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

            // Copiar (todos)
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.textSecondary),
              title: const Text(
                'Copiar texto',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado!')),
                );
              },
            ),

            // Editar (só minhas mensagens)
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.infoBlue),
                title: const Text(
                  'Editar',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(messageId, message);
                },
              ),

            // Deletar (minhas mensagens OU admin)
            if (isMe || isAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorRed),
                title: const Text(
                  'Deletar',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteMessageWithConfirm(messageId, isAdmin && !isMe);
                },
              ),

            // BANIR USUÁRIO (só admin, não pode banir a si mesmo)
            if (isAdmin && !isMe)
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.errorRed),
                title: const Text(
                  'Banir usuário',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _banUserWithConfirm(messageUserId, userName);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessageWithConfirm(String messageId, bool useAdminDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Deletar',
              style: TextStyle(color: AppTheme.errorRed),
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Banir',
              style: TextStyle(color: AppTheme.errorRed),
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
        title: const Text(
          'Editar mensagem',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite a nova mensagem',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
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
          // Header
          _buildHeader(),

          // Lista de mensagens
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                // Erro
                if (snapshot.hasError) {
                  return _buildError();
                }

                // Vazio
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                // Mensagens
                final messages = snapshot.data!.docs;

                // Scroll para o final ao carregar
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

                    return _MessageBubble(
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
                    );
                  },
                );
              },
            ),
          ),

          // Input de mensagem
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Chat Exclusivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Membros premium conectados',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryGreen,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Respondendo a ${_replyingTo!['userName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!['message'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppTheme.errorRed,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
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
            color: AppTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Preview do reply
            _buildReplyPreview(),
            // Preview da imagem selecionada
            if (_selectedImage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Imagem selecionada',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: _removeSelectedImage,
                    ),
                  ],
                ),
              ),
            ],
            // Input de mensagem
            Row(
              children: [
                // Botão de imagem
                IconButton(
                  icon: const Icon(
                    Icons.image,
                    color: AppTheme.primaryGreen,
                  ),
                  onPressed: _isUploading ? null : _pickImage,
                ),
                const SizedBox(width: 8),
                // TextField
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    enabled: !_isUploading,
                    decoration: InputDecoration(
                      hintText: _isUploading
                          ? 'Enviando...'
                          : 'Digite sua mensagem...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
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
                const SizedBox(width: 8),
                // Botão enviar
                GestureDetector(
                  onTap: _isUploading ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isUploading
                          ? AppTheme.textTertiary
                          : AppTheme.primaryGreen,
                      shape: BoxShape.circle,
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
                            Icons.send,
                            color: Colors.white,
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 100, height: 14),
                    SizedBox(height: 8),
                    SkeletonLoader(width: double.infinity, height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          SizedBox(height: 16),
          Text(
            'Erro ao carregar mensagens',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
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
        children: const [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seja o primeiro a enviar uma mensagem!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
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
          // Avatar
          userPhotoUrl != null && userPhotoUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(userPhotoUrl!),
                  backgroundColor: isAdmin
                      ? AppTheme.primaryGreen
                      : AppTheme.cardMedium,
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppTheme.primaryGreen
                        : AppTheme.cardMedium,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.successGreen],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Mensagem
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                          : AppTheme.cardMedium,
                      borderRadius: BorderRadius.circular(12),
                      border: isMe
                          ? Border.all(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview do reply (se existir)
                        if (replyToMessage != null && replyToMessage!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.primaryGreen,
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
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  replyToMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
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
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: AppTheme.cardMedium,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 100,
                                  color: AppTheme.cardMedium,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: AppTheme.textTertiary,
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (message.isNotEmpty) const SizedBox(height: 8),
                        ],
                        // Texto (se existir)
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        if (editedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '(editada)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
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
