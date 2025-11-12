import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para gerenciar badges de notificação nas tabs
class BadgeService {
  static const String _keyLastPostView = 'last_post_view';
  static const String _keyLastSignalView = 'last_signal_view';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  /// Marca posts como visualizados
  Future<void> markPostsAsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPostView, DateTime.now().millisecondsSinceEpoch);
  }

  /// Marca sinais como visualizados
  Future<void> markSignalsAsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSignalView, DateTime.now().millisecondsSinceEpoch);
  }

  /// Verifica se há novos posts
  Stream<bool> hasNewPosts() async* {
    if (_userId == null) {
      yield false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastViewTimestamp = prefs.getInt(_keyLastPostView) ?? 0;

    await for (final snapshot in _firestore
        .collection('alano_posts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()) {
      if (snapshot.docs.isEmpty) {
        yield false;
        continue;
      }

      final latestPost = snapshot.docs.first;
      final createdAt = (latestPost.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

      yield createdAt > lastViewTimestamp;
    }
  }

  /// Verifica se há novos sinais
  Stream<bool> hasNewSignals() async* {
    if (_userId == null) {
      yield false;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastViewTimestamp = prefs.getInt(_keyLastSignalView) ?? 0;

    await for (final snapshot in _firestore
        .collection('signals')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()) {
      if (snapshot.docs.isEmpty) {
        yield false;
        continue;
      }

      final latestSignal = snapshot.docs.first;
      final timestamp = (latestSignal.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

      yield timestamp > lastViewTimestamp;
    }
  }

  /// Obtém o Stream de contagem de mensagens não lidas do chat
  Stream<bool> hasUnreadMessages() async* {
    if (_userId == null) {
      yield false;
      return;
    }

    await for (final snapshot in _firestore
        .collection('chats')
        .where('participants', arrayContains: _userId)
        .snapshots()) {

      int totalUnread = 0;
      for (var chatDoc in snapshot.docs) {
        final unreadCount = chatDoc.data()['unreadCount_$_userId'] as int? ?? 0;
        totalUnread += unreadCount;
      }

      yield totalUnread > 0;
    }
  }
}
