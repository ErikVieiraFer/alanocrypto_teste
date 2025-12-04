import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<NotificationPreferences> getPreferencesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(NotificationPreferences());
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return NotificationPreferences();
      }

      final data = snapshot.data();
      if (data == null || data['notificationPreferences'] == null) {
        return NotificationPreferences();
      }

      return NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>,
      );
    });
  }

  Future<NotificationPreferences> getPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return NotificationPreferences();
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return NotificationPreferences();
      }

      final data = doc.data();
      if (data == null || data['notificationPreferences'] == null) {
        return NotificationPreferences();
      }

      return NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Erro ao buscar preferências: $e');
      return NotificationPreferences();
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': preferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Preferências de notificação atualizadas com sucesso');
    } catch (e) {
      debugPrint('Erro ao atualizar preferências: $e');
      rethrow;
    }
  }

  Future<void> updateSinglePreference(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences.$key': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Preferência $key atualizada para $value');
    } catch (e) {
      debugPrint('Erro ao atualizar preferência $key: $e');
      rethrow;
    }
  }

  Future<void> initializeDefaultPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data()?['notificationPreferences'] == null) {
        final defaultPreferences = NotificationPreferences();
        await _firestore.collection('users').doc(user.uid).set(
          {
            'notificationPreferences': defaultPreferences.toMap(),
          },
          SetOptions(merge: true),
        );
        debugPrint('Preferências padrão inicializadas');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar preferências padrão: $e');
    }
  }
}
