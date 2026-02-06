import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SignalType { long, short }

enum SignalStatus { active, completed, stopped }

class Signal {
  final String id;
  final String coin;
  final SignalType type;
  final String entry;
  final SignalStatus status;
  final String confidence;
  final String strategy;
  final String rsiValue;
  final String timeframe;
  final List<String> viewedBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? profit;

  Signal({
    required this.id,
    required this.coin,
    required this.type,
    required this.entry,
    required this.status,
    required this.confidence,
    this.strategy = 'Não especificado',
    this.rsiValue = 'N/A',
    this.timeframe = 'N/A',
    required this.viewedBy,
    required this.createdAt,
    this.completedAt,
    this.profit,
  });

  factory Signal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    SignalType parseType(String? typeStr) {
      if (typeStr == null) return SignalType.long;
      final normalized = typeStr.toUpperCase();
      return normalized == 'SHORT' ? SignalType.short : SignalType.long;
    }

    SignalStatus parseStatus(String? statusStr) {
      if (statusStr == null) return SignalStatus.active;
      final normalized = statusStr.toLowerCase();
      if (normalized == 'ativo' || normalized == 'active') return SignalStatus.active;
      if (normalized == 'finalizado' || normalized == 'completed' || normalized == 'closed')
        return SignalStatus.completed;
      if (normalized == 'stopped' || normalized == 'stop loss') return SignalStatus.stopped;
      return SignalStatus.active;
    }

    return Signal(
      id: doc.id,
      coin: data['coin'] ?? '',
      type: parseType(data['type']),
      entry: data['entry']?.toString() ?? '0',
      status: parseStatus(data['status']),
      confidence: data['confidence']?.toString() ?? 'N/A',
      strategy: data['strategy']?.toString() ?? 'Não especificado',
      rsiValue: data['rsiValue']?.toString() ?? 'N/A',
      timeframe: data['timeframe']?.toString() ?? 'N/A',
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      profit: data['profit'] != null
          ? (data['profit'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coin': coin,
      'type': typeLabel,
      'entry': entry,
      'status': statusLabel,
      'confidence': confidence,
      'strategy': strategy,
      'rsiValue': rsiValue,
      'timeframe': timeframe,
      'viewedBy': viewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'profit': profit,
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

  String get formattedCoin {
    if (coin.length == 6) {
      return '${coin.substring(0, 3)}/${coin.substring(3)}';
    }
    return coin;
  }

  String get confidenceLabel {
    final conf = confidence.toLowerCase();
    if (conf == 'alta' || conf == 'high') return 'Alta';
    if (conf == 'média' || conf == 'media' || conf == 'medium') return 'Média';
    if (conf == 'baixa' || conf == 'low') return 'Baixa';
    return confidence;
  }

  String get confidenceEmoji {
    final conf = confidenceLabel.toLowerCase();
    if (conf == 'alta') return '🔥';
    if (conf == 'média') return '⚡';
    return '⚠️';
  }
}
