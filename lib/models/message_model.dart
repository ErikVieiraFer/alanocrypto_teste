import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> readBy;

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
    List<String>? readBy,
  }) : reactions = reactions ?? {},
       readBy = readBy ?? [];

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
      'readBy': readBy,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      imageUrl: json['imageUrl'] as String?,
      reactions: Map<String, List<String>>.from(
        (json['reactions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key,
            List<String>.from(value as List),
          ),
        ),
      ),
      replyToId: json['replyToId'] as String?,
      replyToText: json['replyToText'] as String?,
      replyToUserName: json['replyToUserName'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  Message copyWith({
    String? id,
    String? text,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? timestamp,
    String? imageUrl,
    Map<String, List<String>>? reactions,
    String? replyToId,
    String? replyToText,
    String? replyToUserName,
    bool? isEdited,
    List<String>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToUserName: replyToUserName ?? this.replyToUserName,
      isEdited: isEdited ?? this.isEdited,
      readBy: readBy ?? this.readBy,
    );
  }
}
