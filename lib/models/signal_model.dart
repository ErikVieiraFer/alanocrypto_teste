import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SignalType { long, short }
enum SignalStatus { active, completed, stopped }

class Signal {
  final String id;
  final String coin;
  final SignalType type;
  final double entry;
  final List<double> targets;
  final double stopLoss;
  final SignalStatus status;
  final double? profit;
  final int confidence;
  final List<String> viewedBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  Signal({
    required this.id,
    required this.coin,
    required this.type,
    required this.entry,
    required this.targets,
    required this.stopLoss,
    required this.status,
    this.profit,
    required this.confidence,
    required this.viewedBy,
    required this.createdAt,
    this.completedAt,
  });

  factory Signal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Signal(
      id: doc.id,
      coin: data['coin'] ?? '',
      type: SignalType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SignalType.long,
      ),
      entry: (data['entry'] ?? 0).toDouble(),
      targets: List<double>.from(
        (data['targets'] ?? []).map((e) => (e as num).toDouble()),
      ),
      stopLoss: (data['stopLoss'] ?? 0).toDouble(),
      status: SignalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SignalStatus.active,
      ),
      profit: data['profit'] != null ? (data['profit'] as num).toDouble() : null,
      confidence: data['confidence'] ?? 0,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
  return {
    'coin': coin,
    'type': type.name,
    'entry': entry,
    'targets': targets,
    'stopLoss': stopLoss,
    'status': status.name,
    'profit': profit,
    'confidence': confidence,
    'viewedBy': viewedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}

  String get typeLabel => type == SignalType.long ? 'LONG' : 'SHORT';
  
  String get statusLabel {
    switch (status) {
      case SignalStatus.active:
        return 'Ativo';
      case SignalStatus.completed:
        return 'Finalizado';
      case SignalStatus.stopped:
        return 'Stop Loss';
    }
  }

  Color get typeColor {
    return type == SignalType.long 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFF44336);
  }

  Color get statusColor {
    switch (status) {
      case SignalStatus.active:
        return const Color(0xFF2196F3);
      case SignalStatus.completed:
        return const Color(0xFF4CAF50);
      case SignalStatus.stopped:
        return const Color(0xFFF44336);
    }
  }
}