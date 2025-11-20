import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Suporta: youtube.com/watch?v=ID e youtu.be/ID
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
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
    return GestureDetector(
      onTap: () => _showCourseModal(course),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f26),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              course['thumbnailUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: course['thumbnailUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF2a2f36),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FF88),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2a2f36),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF00FF88),
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2a2f36),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF00FF88),
                        size: 40,
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
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Title
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  course['title'] ?? 'Sem título',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Play icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 16,
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
      // Buscar dados do usuário
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

  Widget _buildYouTubeEmbed() {
    // Mostrar thumbnail com botão para abrir no YouTube
    // Funciona em todas as plataformas sem problemas de CORS
    return GestureDetector(
      onTap: _openInYouTube,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: const Color(0xFF2a2f36),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FF88),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: const Color(0xFF2a2f36),
                child: const Center(
                  child: Icon(
                    Icons.video_library,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Overlay escuro
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Botão de play
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.black,
                size: 48,
              ),
            ),
            // Texto "Assistir no YouTube"
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Assistir no YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                      // YouTube Player/Embed
                      _buildYouTubeEmbed(),

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
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text(
                              'Erro ao carregar comentários',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00FF88),
                              ),
                            );
                          }

                          final comments = snapshot.data?.docs ?? [];

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
                              final dateStr = createdAt != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a1f26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFF00FF88),
                                          backgroundImage: data['userPhoto'] != null && data['userPhoto'].isNotEmpty
                                              ? NetworkImage(data['userPhoto'])
                                              : null,
                                          child: data['userPhoto'] == null || data['userPhoto'].isEmpty
                                              ? const Icon(Icons.person, size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['userName'] ?? 'Usuário',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
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
                                        if (isOwner)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () => _deleteComment(doc.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
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
