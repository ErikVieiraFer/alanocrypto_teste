import 'package:cloud_firestore/cloud_firestore.dart';

class AlanoPost {
  final String id;
  final String title;
  final String content;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? imageUrl;
  final List<String> likedBy;
  final List<String> viewedBy;
  final int views;
  final DateTime createdAt;

  AlanoPost({
    required this.id,
    required this.title,
    required this.content,
    this.videoUrl,
    this.thumbnailUrl,
    this.imageUrl,
    required this.likedBy,
    required this.viewedBy,
    required this.views,
    required this.createdAt,
  });

  factory AlanoPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlanoPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      videoUrl: data['videoUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      imageUrl: data['imageUrl'],
      likedBy: List<String>.from(data['likedBy'] ?? []),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      views: data['views'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': imageUrl,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String? get videoId {
    if (videoUrl == null) return null;

    final uri = Uri.tryParse(videoUrl!);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    return null;
  }

  String? get autoThumbnailUrl {
    final id = videoId;
    if (id != null) {
      return 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
    }
    return thumbnailUrl;
  }
}
