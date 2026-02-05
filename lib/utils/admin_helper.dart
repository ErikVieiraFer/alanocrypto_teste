import 'package:firebase_auth/firebase_auth.dart';

class AdminHelper {
  static const List<String> _adminUids = [
    'MSnKrBPj5uZK3JK8LsB8CeHLdb82',
    'XHMsmRONXcOp3vm7VM3326P1DSt2',
  ];

  static bool? _cachedIsAdmin;

  static List<String> get adminUids => _adminUids;

  static bool isAdmin(String uid) {
    return _adminUids.contains(uid);
  }

  static bool isCurrentUserAdmin() {
    if (_cachedIsAdmin != null) return _cachedIsAdmin!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _cachedIsAdmin = _adminUids.contains(user.uid);
    return _cachedIsAdmin!;
  }

  static void clearCache() {
    _cachedIsAdmin = null;
  }
}
