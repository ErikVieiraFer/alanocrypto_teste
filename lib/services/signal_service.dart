import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/signal_model.dart';
import '../models/notification_model.dart';

class SignalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Signal>> getSignals({SignalType? filter, int? lastMinutes}) {
    final cutoffTime = lastMinutes != null
        ? DateTime.now().subtract(Duration(minutes: lastMinutes))
        : null;

    Query query = _firestore.collection('signals');

    if (cutoffTime != null) {
      query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime));
    }

    query = query.orderBy('createdAt', descending: true);

    if (filter != null) {
      query = query.where('type', isEqualTo: filter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Signal.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Signal>> getActiveSignals({SignalType? filter, int lastMinutes = 30}) {
    final cutoffTime = DateTime.now().subtract(Duration(minutes: lastMinutes));
    debugPrint('📊 getActiveSignals: cutoffTime=$cutoffTime, lastMinutes=$lastMinutes');

    Query query = _firestore
        .collection('signals')
        .where('status', whereIn: ['active', 'Active', 'Ativo', 'ativo'])
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime))
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      debugPrint('📊 getActiveSignals: ${snapshot.docs.length} docs encontrados');
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📊 Signal: id=${doc.id}, status=${data['status']}, coin=${data['coin']}, createdAt=${data['createdAt']}');
      }

      if (snapshot.docs.isEmpty) {
        debugPrint('📊 Nenhum sinal ativo encontrado. Buscando TODOS os sinais...');
        _firestore.collection('signals').orderBy('createdAt', descending: true).limit(5).get().then((allDocs) {
          debugPrint('📊 Últimos 5 sinais (qualquer status):');
          for (final doc in allDocs.docs) {
            final data = doc.data();
            debugPrint('📊   id=${doc.id}, status=${data['status']}, coin=${data['coin']}, createdAt=${data['createdAt']}');
          }
        });
      }

      var signals = snapshot.docs.map((doc) => Signal.fromFirestore(doc)).toList();

      if (filter != null) {
        signals = signals.where((s) => s.type == filter).toList();
      }

      return signals;
    });
  }

  Stream<List<Signal>> getCompletedSignals({SignalType? filter}) {
    Query query = _firestore
        .collection('signals')
        .where('status', whereIn: [
          'completed',
          'Completed',
          'finalizado',
          'Finalizado',
          'stopped',
          'Stopped',
          'closed',
          'Closed',
          'Stop Loss',
        ])
        .orderBy('createdAt', descending: true);

    if (filter != null) {
      query = query.where('type', isEqualTo: filter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Signal.fromFirestore(doc)).toList();
    });
  }

  Future<bool> createSignal({
    required String coin,
    required SignalType type,
    required String entry,
    required String confidence,
    String strategy = 'Não especificado',
    String rsiValue = 'N/A',
    String timeframe = 'N/A',
  }) async {
    try {
      final newSignal = Signal(
        id: '',
        coin: coin,
        type: type,
        entry: entry,
        confidence: confidence,
        strategy: strategy,
        rsiValue: rsiValue,
        timeframe: timeframe,
        status: SignalStatus.active,
        viewedBy: [],
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('signals')
          .add(newSignal.toFirestore());
      await _createNotificationsForAllUsers(docRef.id, coin);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createNotificationsForAllUsers(
    String signalId,
    String coin,
  ) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      if (usersSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      final notificationsCollection = _firestore.collection('notifications');

      for (final userDoc in usersSnapshot.docs) {
        final newNotifRef = notificationsCollection.doc();
        batch.set(newNotifRef, {
          'userId': userDoc.id,
          'type': NotificationType.signal.name,
          'title': 'Novo Sinal',
          'content': 'Novo sinal para $coin disponível!',
          'read': false,
          'relatedId': signalId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      // Error creating notifications
    }
  }

  Future<int> getSignalsCount() async {
    try {
      final snapshot = await _firestore.collection('signals').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  String formatSignalText(Signal signal) {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('${signal.type == SignalType.long ? '📈' : '📉'} SINAL DE TRADING');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('💰 Moeda: ${signal.formattedCoin}');
    buffer.writeln('📊 Tipo: ${signal.typeLabel}');
    buffer.writeln('');
    buffer.writeln('💵 Entrada: \$${signal.entry}');
    buffer.writeln('');
    if (signal.strategy != 'Não especificado') {
      buffer.writeln('📊 Estratégia: ${signal.strategy}');
    }
    if (signal.rsiValue != 'N/A') {
      buffer.writeln('📈 RSI Atual: ${signal.rsiValue}');
    }
    if (signal.timeframe != 'N/A') {
      buffer.writeln('⏱️ Timeframe: ${signal.timeframe}');
    }
    buffer.writeln('');
    buffer.writeln('${signal.confidenceEmoji} Confiança: ${signal.confidenceLabel}');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚠️ AVISO: Este não é um conselho financeiro.');
    buffer.writeln('Opere por sua conta e risco.');
    buffer.writeln('');
    buffer.writeln('📲 AlanoCryptoFX');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }
}
