import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../theme/app_theme.dart';

typedef OnSendCallback = void Function(
  String text,
  PickedImageFile? image,
  List<Mention> mentions,
);

const _mentionRegex = r'(\s|^)@\w*';

// Wrapper class to handle images on both mobile and web
class PickedImageFile {
  final File? file; // For mobile
  final Uint8List? bytes; // For web

  PickedImageFile({this.file, this.bytes});

  bool get hasData => file != null || bytes != null;
}

class MessageInput extends StatefulWidget implements PreferredSizeWidget {
  final OnSendCallback onSend;
  final UserService userService;
  final String? replyToUserName;
  final String? replyToText;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.userService,
    this.replyToUserName,
    this.replyToText,
    this.onCancelReply,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _mentionQueryController = BehaviorSubject<String>();

  PickedImageFile? _pickedImage;
  bool _isSending = false;
  bool _showMentionList = false;
  List<UserModel> _mentionUsers = [];
  List<Mention> _mentions = [];

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _mentionQueryController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _mentionQueryController
        .debounceTime(const Duration(milliseconds: 300))
        .distinct()
        .listen(_searchUsers);
  }

  void _onTextChanged() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;

    if (cursorPos == -1) {
      setState(() => _showMentionList = false);
      return;
    }

    final textBeforeCursor = text.substring(0, cursorPos);
    final matches = RegExp(_mentionRegex).allMatches(textBeforeCursor);

    RegExpMatch? activeMatch;
    for (final match in matches) {
      if (match.end == cursorPos) {
        activeMatch = match;
        break;
      }
    }

    if (activeMatch != null && activeMatch.group(0) != null) {
      final query = activeMatch.group(0)!.trim().substring(1);
      print('✍️ Detectado @ com query: "$query"');
      _mentionQueryController.add(query.toLowerCase());
      setState(() => _showMentionList = true);
    } else {
      if (_showMentionList) {
        print('❌ @ removido, fechando lista');
      }
      setState(() => _showMentionList = false);
    }

    _mentions.removeWhere((mention) {
      if (mention.startIndex >= text.length || (mention.startIndex + mention.length) > text.length) {
        return true;
      }
      final mentionText = text.substring(mention.startIndex, mention.startIndex + mention.length);
      return mentionText != '@${mention.displayName}';
    });
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    print('🔍 MessageInput: Buscando usuários para query: "$query"');
    final users = await widget.userService.searchApprovedUsers(query, limit: 10);
    print('📥 MessageInput: Recebidos ${users.length} usuários');
    if (users.isNotEmpty) {
      print('👥 MessageInput: ${users.map((u) => u.displayName).join(", ")}');
    }
    setState(() => _mentionUsers = users);
  }

  void _onUserSelected(UserModel user) {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPos);

    final lastAt = textBeforeCursor.lastIndexOf('@');
    if (lastAt == -1) return;

    final newText = '${text.substring(0, lastAt)}@${user.displayName} ${text.substring(cursorPos)}';

    final newMention = Mention(
      userId: user.uid,
      displayName: user.displayName,
      startIndex: lastAt,
      length: user.displayName.length + 1,
    );
    _mentions.add(newMention);

    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: lastAt + newMention.length + 1),
    );

    setState(() {
      _showMentionList = false;
      _mentionUsers = [];
    });
    _focusNode.requestFocus();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _pickedImage = PickedImageFile(bytes: bytes);
          });
        } else {
          setState(() {
            _pickedImage = PickedImageFile(file: File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() => _pickedImage = null);
  }

  Future<void> _sendMessage() async {
    if (_isSending || (_textController.text.trim().isEmpty && _pickedImage == null)) {
      return;
    }

    setState(() => _isSending = true);

    try {
      widget.onSend(_textController.text.trim(), _pickedImage, List.from(_mentions));
      _textController.clear();
      setState(() {
        _pickedImage = null;
        _mentions.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar mensagem: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReply = widget.replyToUserName != null;

    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showMentionList) _buildMentionList(),
          if (hasReply) _buildReplyBar(theme),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildMentionList() {
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: _mentionUsers.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhum usuário encontrado')))
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _mentionUsers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _mentionUsers[index];
                  return ListTile(
                    onTap: () => _onUserSelected(user),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL) : null,
                      child: user.photoURL.isEmpty ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '') : null,
                    ),
                    title: Text(user.displayName),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildReplyBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: theme.cardColor.withAlpha(100)),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18, color: AppTheme.accentGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Respondendo a ${widget.replyToUserName}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                Text(widget.replyToText!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: widget.onCancelReply),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pickedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb ? Image.memory(_pickedImage!.bytes!, height: 100, width: 100, fit: BoxFit.cover) : Image.file(_pickedImage!.file!, height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  Positioned(top: 4, right: 4, child: GestureDetector(onTap: _removeImage, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                ],
              ),
            if (_pickedImage != null) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: _pickImage),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.primaryColor,
                    child: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
