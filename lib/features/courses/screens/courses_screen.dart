import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .orderBy('order', descending: false)
          .get();

      setState(() {
        _courses = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _showCourseModal(Map<String, dynamic> course) {
    final videoId = _extractYouTubeId(course['videoUrl'] ?? '');

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL do vídeo inválida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseModal(
        course: course,
        videoId: videoId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cursos',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aprenda com nossos conteúdos exclusivos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FF88),
                      ),
                    )
                  : _courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhum curso disponível',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Em breve novos conteúdos!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchCourses,
                          color: const Color(0xFF00FF88),
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 16 / 9,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final course = _courses[index];
                              return _buildCourseCard(course);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    // Gera thumbnail do YouTube se não tiver thumbnail customizada
    String? thumbnailUrl = course['thumbnailUrl'];
    if (thumbnailUrl == null || thumbnailUrl.toString().isEmpty) {
      final videoId = _extractYouTubeId(course['videoUrl'] ?? '');
      if (videoId != null) {
        thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }

    return GestureDetector(
      onTap: () => _showCourseModal(course),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f26),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail (custom ou do YouTube)
              thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF2a2f36),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FF88),
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2a2f36),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF00FF88),
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2a2f36),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF00FF88),
                        size: 24,
                      ),
                    ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Text(
                  course['title'] ?? 'Sem título',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Play icon
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseModal extends StatefulWidget {
  final Map<String, dynamic> course;
  final String videoId;

  const _CourseModal({
    required this.course,
    required this.videoId,
  });

  @override
  State<_CourseModal> createState() => _CourseModalState();
}

class _CourseModalState extends State<_CourseModal> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;
  late YoutubePlayerController _youtubeController;
  String? _editingCommentId;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editController.dispose();
    _youtubeController.close();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para comentar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingComment = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('course_comments').add({
        'courseId': widget.course['id'],
        'userId': user.uid,
        'userName': userData['displayName'] ?? userData['name'] ?? user.displayName ?? 'Usuário',
        'userPhoto': userData['photoURL'] ?? user.photoURL ?? '',
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário adicionado!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao comentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f26),
        title: const Text(
          'Excluir comentário?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('course_comments')
            .doc(commentId)
            .delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _startEditing(String commentId, String currentText) {
    setState(() {
      _editingCommentId = commentId;
      _editController.text = currentText;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCommentId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(String commentId) async {
    final newText = _editController.text.trim();
    if (newText.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('course_comments')
          .doc(commentId)
          .update({
        'comment': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _editingCommentId = null;
        _editController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário editado!'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao editar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E1116),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assistir Curso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube Player Embedded
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(
                          controller: _youtubeController,
                          aspectRatio: 16 / 9,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.course['title'] ?? 'Sem título',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        widget.course['description'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFF2a2f36)),
                      const SizedBox(height: 16),

                      // Comments section
                      const Text(
                        'Comentários',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Comments list
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('course_comments')
                            .where('courseId', isEqualTo: widget.course['id'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            debugPrint('Erro nos comentários: ${snapshot.error}');
                            return Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Erro ao carregar comentários:\n${snapshot.error}',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00FF88),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          // Ordenar no cliente (evita necessidade de índice)
                          final comments = List<QueryDocumentSnapshot>.from(docs);
                          comments.sort((a, b) {
                            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
                            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime); // Descending
                          });

                          if (comments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: const Center(
                                child: Text(
                                  'Nenhum comentário ainda.\nSeja o primeiro a comentar!',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: comments.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final isOwner = data['userId'] == FirebaseAuth.instance.currentUser?.uid;
                              final createdAt = data['createdAt'] as Timestamp?;
                              final editedAt = data['editedAt'] as Timestamp?;
                              final dateStr = createdAt != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
                                  : '';
                              final isEditing = _editingCommentId == doc.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a1f26),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isEditing
                                      ? Border.all(color: const Color(0xFF00FF88), width: 1)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFF00FF88),
                                          backgroundImage: data['userPhoto'] != null && data['userPhoto'].toString().isNotEmpty
                                              ? NetworkImage(data['userPhoto'])
                                              : null,
                                          child: data['userPhoto'] == null || data['userPhoto'].toString().isEmpty
                                              ? const Icon(Icons.person, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    data['userName'] ?? 'Usuário',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (editedAt != null) ...[
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      '(editado)',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 10,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isOwner && !isEditing) ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFF00FF88),
                                              size: 18,
                                            ),
                                            onPressed: () => _startEditing(doc.id, data['comment'] ?? ''),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Editar',
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () => _deleteComment(doc.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Excluir',
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (isEditing)
                                      Column(
                                        children: [
                                          TextField(
                                            controller: _editController,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            maxLines: null,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFF2a2f36),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.all(12),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: _cancelEditing,
                                                child: const Text(
                                                  'Cancelar',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () => _saveEdit(doc.id),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF00FF88),
                                                  foregroundColor: Colors.black,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        data['comment'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 80), // Space for input
                    ],
                  ),
                ),
              ),

              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1a1f26),
                  border: Border(
                    top: BorderSide(color: Color(0xFF2a2f36)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Escreva um comentário...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF2a2f36),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSendingComment
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00FF88),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _addComment,
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFF00FF88),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
