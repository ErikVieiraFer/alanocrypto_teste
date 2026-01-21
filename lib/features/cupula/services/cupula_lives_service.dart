import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CupulaLive {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String? thumbnailUrl;
  final bool isLive;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final String createdBy;
  final String authorName;

  CupulaLive({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    this.thumbnailUrl,
    required this.isLive,
    this.scheduledAt,
    required this.createdAt,
    required this.createdBy,
    required this.authorName,
  });

  factory CupulaLive.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CupulaLive(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      isLive: data['isLive'] ?? false,
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      authorName: data['authorName'] ?? 'Alano Crypto',
    );
  }

  String get youtubeVideoId => extractYoutubeId(youtubeUrl);

  String get effectiveThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    final videoId = youtubeVideoId;
    if (videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    return '';
  }

  static String extractYoutubeId(String url) {
    if (url.isEmpty) return '';

    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/live\/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '';
      }
    }

    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(url)) {
      return url;
    }

    return '';
  }
}

class CupulaLivesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CupulaLive>> getLives() {
    debugPrint('📺 CupulaLivesService.getLives() chamado');

    return _firestore
        .collection('cupula_lives')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          debugPrint('📺 Lives snapshot recebido: ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) => CupulaLive.fromFirestore(doc)).toList();
        })
        .handleError((error) {
          debugPrint('❌ Erro no stream de lives: $error');
        });
  }

  Stream<CupulaLive?> getCurrentLive() {
    debugPrint('🔴 CupulaLivesService.getCurrentLive() chamado');

    return _firestore
        .collection('cupula_lives')
        .where('isLive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            debugPrint('🔴 Nenhuma live ao vivo no momento');
            return null;
          }
          debugPrint('🔴 Live ao vivo encontrada!');
          return CupulaLive.fromFirestore(snapshot.docs.first);
        })
        .handleError((error) {
          debugPrint('❌ Erro ao buscar live atual: $error');
        });
  }

  Future<void> incrementViews(String liveId) async {
    await _firestore.collection('cupula_lives').doc(liveId).update({
      'views': FieldValue.increment(1),
    });
  }
}
