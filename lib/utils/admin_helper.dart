import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminHelper {
  static final AdminHelper _instance = AdminHelper._internal();
  factory AdminHelper() => _instance;
  AdminHelper._internal();

  // UIDs dos admins - FALLBACK hardcoded para web (dotenv pode falhar)
  static const List<String> _fallbackAdminUids = [
    'MSnKrBPj5uZK3JK8LsB8CeHLdb82', // Erik
    'XHMsmRONXcOp3vm7VM3326P1DSt2', // Alano
  ];

  // Lista de UIDs dos admins (do .env com fallback)
  static List<String> get adminUids {
    final List<String> uids = [];

    // Tentar carregar do .env
    final envUid1 = dotenv.env['ADMIN_UID'];
    final envUid2 = dotenv.env['ADMIN_UID_2'];

    if (envUid1 != null && envUid1.isNotEmpty) {
      uids.add(envUid1);
    }
    if (envUid2 != null && envUid2.isNotEmpty) {
      uids.add(envUid2);
    }

    // Se nenhum UID foi carregado, usa fallback
    if (uids.isEmpty) {
      debugPrint('⚠️ AdminHelper: .env ADMIN_UIDs vazios, usando fallback');
      return _fallbackAdminUids;
    }

    return uids;
  }

  // Verificar se usuário atual é admin
  static bool isCurrentUserAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ AdminHelper: Nenhum usuário logado');
      return false;
    }

    final isAdmin = adminUids.contains(user.uid);
    debugPrint('🔐 AdminHelper.isCurrentUserAdmin():');
    debugPrint('   User UID: ${user.uid}');
    debugPrint('   Admin UIDs: $adminUids');
    debugPrint('   É admin: $isAdmin');

    return isAdmin;
  }

  // Verificar se um UID específico é admin
  static bool isAdmin(String uid) {
    return adminUids.contains(uid);
  }
}
