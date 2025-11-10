import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/signal_model.dart';
import '../models/notification_model.dart';

class SignalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Signal>> getSignals({SignalType? filter}) {
    Query query = _firestore
        .collection('signals')
        .orderBy('createdAt', descending: true);

    if (filter != null) {
      query = query.where('type', isEqualTo: filter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Signal.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Signal>> getActiveSignals({SignalType? filter}) {
    Query query = _firestore
        .collection('signals')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (filter != null) {
      query = query.where('type', isEqualTo: filter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Signal.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Signal>> getCompletedSignals({SignalType? filter}) {
    Query query = _firestore
        .collection('signals')
        .where('status', whereIn: ['completed', 'stopped'])
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
    required double entry,
    required List<double> targets,
    required double stopLoss,
    required int confidence,
  }) async {
    try {
      final newSignal = Signal(
        id: '',
        coin: coin,
        type: type,
        entry: entry,
        targets: targets,
        stopLoss: stopLoss,
        confidence: confidence,
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
      print('Erro ao criar sinal: $e');
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
      print('Erro ao criar notificações: $e');
    }
  }

  Future<int> getSignalsCount() async {
    try {
      final snapshot = await _firestore.collection('signals').get();
      return snapshot.size;
    } catch (e) {
      print('Erro ao contar sinais: $e');
      return 0;
    }
  }

  String formatSignalText(Signal signal) {
    final buffer = StringBuffer();
    buffer.writeln('🎯 ${signal.coin}');
    buffer.writeln('📊 Tipo: ${signal.typeLabel}');
    buffer.writeln('💰 Entrada: \${signal.entry.toStringAsFixed(2)}');
    buffer.writeln('🎯 Alvos:');
    for (int i = 0; i < signal.targets.length; i++) {
      buffer.writeln(
        '   Alvo ${i + 1}: \${signal.targets[i].toStringAsFixed(2)}',
      );
    }
    buffer.writeln('🛑 Stop Loss: \${signal.stopLoss.toStringAsFixed(2)}');
    buffer.writeln('⚡ Confiança: ${signal.confidence}%');

    return buffer.toString();
  }
}
