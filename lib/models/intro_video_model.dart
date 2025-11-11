import 'package:cloud_firestore/cloud_firestore.dart';

class IntroVideoModel {
  final String title;
  final String description;
  final String videoUrl;
  final bool isActive;

  IntroVideoModel({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.isActive,
  });

  factory IntroVideoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IntroVideoModel(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'isActive': isActive,
    };
  }
}
