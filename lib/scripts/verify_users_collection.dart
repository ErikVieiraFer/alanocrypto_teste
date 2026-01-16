import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script para verificar e corrigir collection users
///
/// COMO USAR:
/// 1. Chamar verifyUsersCollection() uma vez
/// 2. Ver relatório no console
/// 3. Deletar após usar

/// Campos obrigatórios na collection users
const requiredFields = {
  'displayName': 'string',
  'email': 'string',
  'photoURL': 'string',
  'isAdmin': 'boolean',
};

/// Verifica se todos os usuários têm os campos necessários
Future<void> verifyUsersCollection() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔍 VERIFICANDO COLLECTION USERS...\n');

    final usersSnapshot = await firestore.collection('users').get();

    if (usersSnapshot.docs.isEmpty) {
      print('⚠️  Nenhum usuário encontrado na collection users');
      print('💡 Dica: Os usuários são criados automaticamente no primeiro login\n');
      return;
    }

    print('📊 Total de usuários: ${usersSnapshot.docs.length}\n');

    int completeUsers = 0;
    int incompleteUsers = 0;
    final List<Map<String, dynamic>> issues = [];

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final userId = doc.id;
      final userName = data['displayName'] ?? 'Sem nome';

      final missingFields = <String>[];

      // Verificar cada campo obrigatório
      for (final field in requiredFields.keys) {
        if (!data.containsKey(field)) {
          missingFields.add(field);
        } else if (data[field] == null) {
          missingFields.add('$field (null)');
        }
      }

      if (missingFields.isEmpty) {
        completeUsers++;
      } else {
        incompleteUsers++;
        issues.add({
          'userId': userId,
          'userName': userName,
          'email': data['email'] ?? 'Sem email',
          'missingFields': missingFields,
        });
      }
    }

    // Relatório
    print('✅ Usuários completos: $completeUsers');
    print('⚠️  Usuários incompletos: $incompleteUsers\n');

    if (issues.isNotEmpty) {
      print('📋 DETALHES DOS PROBLEMAS:\n');
      for (int i = 0; i < issues.length; i++) {
        final issue = issues[i];
        print('${i + 1}. ${issue['userName']} (${issue['email']})');
        print('   ID: ${issue['userId']}');
        print('   Campos faltando: ${(issue['missingFields'] as List).join(', ')}');
        print('');
      }
    }

    print('💡 PRÓXIMOS PASSOS:');
    print('   1. Para corrigir automaticamente, execute: fixUsersCollection()');
    print('   2. Para criar usuário atual, execute: ensureCurrentUserExists()');
    print('');

  } catch (e) {
    print('❌ Erro ao verificar usuários: $e');
    rethrow;
  }
}

/// Corrige os campos faltantes automaticamente
Future<void> fixUsersCollection() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🔧 CORRIGINDO COLLECTION USERS...\n');

    final usersSnapshot = await firestore.collection('users').get();
    int fixed = 0;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      // Adicionar campos faltantes com valores padrão
      if (!data.containsKey('displayName') || data['displayName'] == null) {
        updates['displayName'] = data['email']?.split('@')[0] ?? 'Usuário';
      }

      if (!data.containsKey('email') || data['email'] == null) {
        updates['email'] = ''; // Será preenchido no próximo login
      }

      if (!data.containsKey('photoURL')) {
        updates['photoURL'] = null;
      }

      if (!data.containsKey('isAdmin') || data['isAdmin'] == null) {
        updates['isAdmin'] = false;
      }

      // Atualizar se houver campos para adicionar
      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
        fixed++;
        print('✅ Corrigido: ${data['displayName'] ?? doc.id}');
      }
    }

    print('\n🎉 Correção concluída!');
    print('   Total corrigido: $fixed usuários\n');

  } catch (e) {
    print('❌ Erro ao corrigir: $e');
    rethrow;
  }
}

/// Garante que o usuário atual existe na collection users
Future<void> ensureCurrentUserExists() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final user = auth.currentUser;

  if (user == null) {
    print('❌ Nenhum usuário logado');
    return;
  }

  try {
    print('🔍 Verificando usuário atual: ${user.email}\n');

    final userDoc = await firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      print('⚠️  Usuário não existe na collection users');
      print('📝 Criando usuário...\n');

      await firestore.collection('users').doc(user.uid).set({
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Usuário criado com sucesso!');
    } else {
      print('✅ Usuário já existe');

      final data = userDoc.data()!;
      final missing = <String>[];

      if (!data.containsKey('displayName')) missing.add('displayName');
      if (!data.containsKey('email')) missing.add('email');
      if (!data.containsKey('photoURL')) missing.add('photoURL');
      if (!data.containsKey('isAdmin')) missing.add('isAdmin');

      if (missing.isNotEmpty) {
        print('⚠️  Campos faltando: ${missing.join(', ')}');
        print('📝 Atualizando...\n');

        final updates = <String, dynamic>{};
        if (!data.containsKey('displayName')) {
          updates['displayName'] = user.displayName ?? user.email?.split('@')[0] ?? 'Usuário';
        }
        if (!data.containsKey('email')) updates['email'] = user.email ?? '';
        if (!data.containsKey('photoURL')) updates['photoURL'] = user.photoURL;
        if (!data.containsKey('isAdmin')) updates['isAdmin'] = false;

        await userDoc.reference.update(updates);
        print('✅ Usuário atualizado com sucesso!');
      }
    }

    // Mostrar dados finais
    final finalDoc = await firestore.collection('users').doc(user.uid).get();
    final finalData = finalDoc.data()!;

    print('\n📊 DADOS DO USUÁRIO:');
    print('   Nome: ${finalData['displayName']}');
    print('   Email: ${finalData['email']}');
    print('   Foto: ${finalData['photoURL'] != null ? '✅' : '❌'}');
    print('   Admin: ${finalData['isAdmin'] ? 'Sim' : 'Não'}');
    print('');

  } catch (e) {
    print('❌ Erro: $e');
    rethrow;
  }
}

/// Cria um usuário admin manualmente
Future<void> createAdminUser({
  required String userId,
  required String displayName,
  required String email,
  String? photoURL,
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('👑 Criando usuário ADMIN...\n');

    await firestore.collection('users').doc(userId).set({
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isAdmin': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Admin criado com sucesso!');
    print('   Nome: $displayName');
    print('   Email: $email');
    print('   Admin: Sim');
    print('');

  } catch (e) {
    print('❌ Erro ao criar admin: $e');
    rethrow;
  }
}

/// Relatório completo
Future<void> fullReport() async {
  print('═══════════════════════════════════════════════════════\n');
  print('🔍 RELATÓRIO COMPLETO DA COLLECTION USERS\n');
  print('═══════════════════════════════════════════════════════\n');

  await verifyUsersCollection();

  print('═══════════════════════════════════════════════════════\n');
}
