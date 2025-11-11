import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  static const double _initialBalance = 10000.0;

  Stream<List<TransactionModel>> getActiveTransactionsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TransactionModel>> getClosedTransactionsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('status', isEqualTo: 'closed')
        .orderBy('closedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<List<TransactionModel>> getActiveTransactions() async {
    if (_userId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active transactions: $e');
    }
  }

  Future<double> getCurrentBalance() async {
    if (_userId == null) {
      return _initialBalance;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('portfolio')
          .doc('balance')
          .get();

      if (doc.exists) {
        return (doc.data()?['balance'] ?? _initialBalance).toDouble();
      }
      return _initialBalance;
    } catch (e) {
      return _initialBalance;
    }
  }

  Future<void> setBalance(double balance) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('portfolio')
          .doc('balance')
          .set({'balance': balance});
    } catch (e) {
      throw Exception('Error setting balance: $e');
    }
  }

  Future<void> resetPortfolio() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();

      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .get();

      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final balanceRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('portfolio')
          .doc('balance');

      batch.set(balanceRef, {'balance': _initialBalance});

      await batch.commit();
    } catch (e) {
      throw Exception('Error resetting portfolio: $e');
    }
  }

  Future<void> createTransaction({
    required String cryptoId,
    required String cryptoSymbol,
    required String cryptoName,
    required TransactionType type,
    required double quantity,
    required double entryPrice,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final totalCost = quantity * entryPrice;
      final currentBalance = await getCurrentBalance();

      if (type == TransactionType.buy && totalCost > currentBalance) {
        throw Exception('Saldo insuficiente');
      }

      final transaction = TransactionModel(
        id: '',
        userId: _userId!,
        cryptoId: cryptoId,
        cryptoSymbol: cryptoSymbol,
        cryptoName: cryptoName,
        type: type,
        status: TransactionStatus.active,
        quantity: quantity,
        entryPrice: entryPrice,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .add(transaction.toFirestore());

      final newBalance = type == TransactionType.buy
          ? currentBalance - totalCost
          : currentBalance + totalCost;

      await setBalance(newBalance);
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  Future<void> closeTransaction(String transactionId, double exitPrice) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        throw Exception('Transaction not found');
      }

      final transaction = TransactionModel.fromFirestore(doc);
      final currentBalance = await getCurrentBalance();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .doc(transactionId)
          .update({
        'status': 'closed',
        'exitPrice': exitPrice,
        'closedAt': FieldValue.serverTimestamp(),
      });

      final totalExit = transaction.quantity * exitPrice;
      final newBalance = transaction.type == TransactionType.buy
          ? currentBalance + totalExit
          : currentBalance - totalExit;

      await setBalance(newBalance);
    } catch (e) {
      throw Exception('Error closing transaction: $e');
    }
  }
}
