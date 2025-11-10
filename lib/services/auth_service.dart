import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'user_service.dart';

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Flag to prevent multiple simultaneous login attempts
  bool _isSigningIn = false;

  AuthService._internal() {
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges().handleError((error) {
        // Suppress known FlutterFire web interop error
        if (error.toString().contains('JavaScriptObject') ||
            error.toString().contains('_testException')) {
          print('Suprimindo erro conhecido do FlutterFire: $error');
          return;
        }
        throw error;
      });

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-cancelled':
        case 'cancelled-popup-request':
          return 'Login cancelado pelo usuário';
        case 'popup-blocked':
          return 'Pop-up bloqueado. Permita pop-ups para este site';
        case 'popup-closed-by-user':
          return 'Pop-up fechado antes de concluir o login';
        case 'network-request-failed':
          return 'Conexão perdida. Verifique sua internet';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde alguns minutos';
        case 'user-disabled':
          return 'Usuário desabilitado. Entre em contato com o suporte';
        case 'web-storage-unsupported':
          return 'Navegador bloqueando cookies. Ative cookies e tente novamente';
        case 'unauthorized-domain':
          return 'Domínio não autorizado. Entre em contato com o suporte';
        case 'invalid-credential':
          return 'Credenciais inválidas. Tente novamente';
        case 'account-exists-with-different-credential':
          return 'Conta já existe com outro método de login';
        default:
          return 'Erro ao fazer login: ${error.message ?? error.code}';
      }
    }

    return 'Erro inesperado: $error';
  }

  Future<User?> signInWithGoogle() async {
    // Prevent multiple simultaneous login attempts
    if (_isSigningIn) {
      print('Login já em andamento, ignorando nova tentativa');
      return null;
    }

    _isSigningIn = true;

    try {
      if (kIsWeb) {
        UserCredential userCredential;

        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        userCredential = await _auth.signInWithPopup(googleProvider);

        final User? user = userCredential.user;

        if (user != null) {
          await _userService.createOrUpdateUser(user);
        }

        return user;
      } else {
        // Mobile (Android/iOS)
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw AuthException('user-cancelled', 'Login cancelado pelo usuário');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user != null) {
          await _userService.createOrUpdateUser(userCredential.user!);
        }

        return userCredential.user;
      }
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      print('Erro no login com Google: $errorMessage');
      throw AuthException('login-failed', errorMessage);
    } finally {
      _isSigningIn = false;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Erro no logout: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? bio,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        updates['photoURL'] = photoURL;
        await user.updatePhotoURL(photoURL);
      }

      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }
}
