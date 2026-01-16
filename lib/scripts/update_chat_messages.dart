import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para atualizar mensagens antigas do chat com o campo userPhotoUrl
///
/// COMO USAR:
/// 1. Importar este arquivo onde você tiver acesso ao Firestore
/// 2. Chamar updateChatMessages() uma única vez
/// 3. Deletar este arquivo após usar
Future<void> updateChatMessages() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔄 Iniciando atualização das mensagens...');

    // Buscar todas as mensagens
    final messagesSnapshot = await firestore.collection('cupula_chat').get();

    if (messagesSnapshot.docs.isEmpty) {
      print('✅ Nenhuma mensagem para atualizar');
      return;
    }

    print('📊 Encontradas ${messagesSnapshot.docs.length} mensagens');

    int updated = 0;
    int skipped = 0;

    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();

      // Se já tem userPhotoUrl, pular
      if (data.containsKey('userPhotoUrl')) {
        skipped++;
        continue;
      }

      final userId = data['userId'] as String?;

      if (userId == null) {
        print('⚠️  Mensagem ${doc.id} sem userId, pulando...');
        skipped++;
        continue;
      }

      // Buscar dados do usuário
      String? userPhotoUrl;
      try {
        final userDoc = await firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userPhotoUrl = userDoc.data()?['photoURL'] as String?;
        }
      } catch (e) {
        print('⚠️  Erro ao buscar usuário $userId: $e');
      }

      // Atualizar mensagem
      await doc.reference.update({
        'userPhotoUrl': userPhotoUrl,
      });

      updated++;

      if (updated % 10 == 0) {
        print('📝 Atualizadas $updated mensagens...');
      }
    }

    print('');
    print('✅ Atualização concluída!');
    print('   - Atualizadas: $updated mensagens');
    print('   - Puladas: $skipped mensagens');
    print('');

  } catch (e) {
    print('❌ Erro ao atualizar mensagens: $e');
    rethrow;
  }
}

/// Versão simplificada: apenas adiciona campo null
Future<void> updateChatMessagesSimple() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔄 Iniciando atualização simples...');

    final messagesSnapshot = await firestore.collection('cupula_chat').get();

    int updated = 0;

    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();

      // Se já tem userPhotoUrl, pular
      if (data.containsKey('userPhotoUrl')) {
        continue;
      }

      // Adicionar campo null
      await doc.reference.update({
        'userPhotoUrl': null,
      });

      updated++;
    }

    print('✅ Atualizadas $updated mensagens com userPhotoUrl: null');

  } catch (e) {
    print('❌ Erro: $e');
    rethrow;
  }
}
