import 'package:cloud_firestore/cloud_firestore.dart';

class Mention {
  final String userId;
  final String displayName;
  final int startIndex;
  final int length;

  Mention({
    required this.userId,
    required this.displayName,
    required this.startIndex,
    required this.length,
  });

  Map<String, dynamic> toJson() => {'userId': userId, 'displayName': displayName, 'startIndex': startIndex, 'length': length};
  factory Mention.fromJson(Map<String, dynamic> json) => Mention(userId: json['userId'], displayName: json['displayName'], startIndex: json['startIndex'], length: json['length']);
}

class Message {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, List<String>> reactions;
  final String? replyToId;
  final String? replyToText;
  final String? replyToUserName;
  final bool isEdited;
  final List<Mention> mentions;

  Message({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.timestamp,
    this.imageUrl,
    Map<String, List<String>>? reactions,
    this.replyToId,
    this.replyToText,
    this.replyToUserName,
    this.isEdited = false,
    this.mentions = const [],
  }) : reactions = reactions ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToUserName': replyToUserName,
      'isEdited': isEdited,
      'mentions': mentions.map((m) => m.toJson()).toList(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
      reactions: Map<String, List<String>>.from(
        (json['reactions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        ),
      ),
      replyToId: json['replyToId'] as String?,
      replyToText: json['replyToText'] as String?,
      replyToUserName: json['replyToUserName'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((m) => Mention.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
