import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchlistService {
  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<String>> getWatchlistStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('watchlist')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<List<String>> getWatchlist() async {
    if (_userId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('watchlist')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Error fetching watchlist: $e');
    }
  }

  Future<bool> isInWatchlist(String cryptoId) async {
    if (_userId == null) {
      return false;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('watchlist')
          .doc(cryptoId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> addToWatchlist(String cryptoId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('watchlist')
          .doc(cryptoId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error adding to watchlist: $e');
    }
  }

  Future<void> removeFromWatchlist(String cryptoId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('watchlist')
          .doc(cryptoId)
          .delete();
    } catch (e) {
      throw Exception('Error removing from watchlist: $e');
    }
  }

  Future<void> toggleWatchlist(String cryptoId) async {
    final isInList = await isInWatchlist(cryptoId);

    if (isInList) {
      await removeFromWatchlist(cryptoId);
    } else {
      await addToWatchlist(cryptoId);
    }
  }
}
