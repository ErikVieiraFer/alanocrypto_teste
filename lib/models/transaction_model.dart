import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { buy, sell }
enum TransactionStatus { active, closed }

class TransactionModel {
  final String id;
  final String userId;
  final String forexPair;
  final String cryptoSymbol;
  final String forexPairName;
  final TransactionType type;
  final TransactionStatus status;
  final double quantity;
  final double entryPrice;
  final double? exitPrice;
  final DateTime createdAt;
  final DateTime? closedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.forexPair,
    required this.cryptoSymbol,
    required this.forexPairName,
    required this.type,
    required this.status,
    required this.quantity,
    required this.entryPrice,
    this.exitPrice,
    required this.createdAt,
    this.closedAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      forexPair: data['forexPair'] ?? data['cryptoId'] ?? '',
      cryptoSymbol: data['cryptoSymbol'] ?? '',
      forexPairName: data['forexPairName'] ?? data['cryptoName'] ?? '',
      type: data['type'] == 'buy' ? TransactionType.buy : TransactionType.sell,
      status: data['status'] == 'active'
          ? TransactionStatus.active
          : TransactionStatus.closed,
      quantity: (data['quantity'] ?? 0).toDouble(),
      entryPrice: (data['entryPrice'] ?? 0).toDouble(),
      exitPrice: data['exitPrice']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      closedAt: data['closedAt'] != null
          ? (data['closedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'forexPair': forexPair,
      'cryptoSymbol': cryptoSymbol,
      'forexPairName': forexPairName,
      'type': type == TransactionType.buy ? 'buy' : 'sell',
      'status': status == TransactionStatus.active ? 'active' : 'closed',
      'quantity': quantity,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  double get totalEntry => quantity * entryPrice;

  double get totalExit {
    if (exitPrice == null) return 0;
    return quantity * exitPrice!;
  }

  double calculatePnL(double currentPrice) {
    final currentTotal = quantity * currentPrice;
    if (type == TransactionType.buy) {
      return currentTotal - totalEntry;
    } else {
      return totalEntry - currentTotal;
    }
  }

  double calculatePnLPercentage(double currentPrice) {
    final pnl = calculatePnL(currentPrice);
    return (pnl / totalEntry) * 100;
  }

  String formattedPnL(double currentPrice) {
    final pnl = calculatePnL(currentPrice);
    return '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}';
  }

  String formattedPnLPercentage(double currentPrice) {
    final percentage = calculatePnLPercentage(currentPrice);
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%';
  }
}
