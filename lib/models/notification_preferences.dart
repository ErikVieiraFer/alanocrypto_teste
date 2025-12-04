class NotificationPreferences {
  final bool posts;
  final bool signals;
  final bool mentions;
  final bool chatMessages;
  final ChatMessagesThrottle? chatMessagesThrottle;

  NotificationPreferences({
    this.posts = true,
    this.signals = true,
    this.mentions = true,
    this.chatMessages = false,
    this.chatMessagesThrottle,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      posts: map['posts'] ?? true,
      signals: map['signals'] ?? true,
      mentions: map['mentions'] ?? true,
      chatMessages: map['chatMessages'] ?? false,
      chatMessagesThrottle: map['chatMessagesThrottle'] != null
          ? ChatMessagesThrottle.fromMap(map['chatMessagesThrottle'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'posts': posts,
      'signals': signals,
      'mentions': mentions,
      'chatMessages': chatMessages,
      'chatMessagesThrottle': chatMessagesThrottle?.toMap() ?? ChatMessagesThrottle().toMap(),
    };
  }

  NotificationPreferences copyWith({
    bool? posts,
    bool? signals,
    bool? mentions,
    bool? chatMessages,
    ChatMessagesThrottle? chatMessagesThrottle,
  }) {
    return NotificationPreferences(
      posts: posts ?? this.posts,
      signals: signals ?? this.signals,
      mentions: mentions ?? this.mentions,
      chatMessages: chatMessages ?? this.chatMessages,
      chatMessagesThrottle: chatMessagesThrottle ?? this.chatMessagesThrottle,
    );
  }
}

class ChatMessagesThrottle {
  final bool enabled;
  final int maxPerHour;
  final int batchInterval;

  ChatMessagesThrottle({
    this.enabled = true,
    this.maxPerHour = 4,
    this.batchInterval = 15,
  });

  factory ChatMessagesThrottle.fromMap(Map<String, dynamic> map) {
    return ChatMessagesThrottle(
      enabled: map['enabled'] ?? true,
      maxPerHour: map['maxPerHour'] ?? 4,
      batchInterval: map['batchInterval'] ?? 15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'maxPerHour': maxPerHour,
      'batchInterval': batchInterval,
    };
  }
}
