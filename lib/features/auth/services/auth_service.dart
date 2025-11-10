import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Login com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      //auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      await _saveUserData(userCredential.user!);

      return userCredential;
    } catch (e) {
      print('Erro no login: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // NOVO USUÁRIO - criar com approved: false
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'bio': '',
          'approved': false, // Novo usuário precisa aprovação
          'blocked': false,
          'emailVerified': false,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };
        await userDoc.set(userData);
        print('✅ Novo usuário criado: ${user.email} - Precisa aprovação');
      } else {
        // USUÁRIO EXISTENTE - atualizar APENAS lastLogin (não mexer em approved)
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
        print('✅ Usuário existente atualizado: ${user.email}');
      }
    } catch (e) {
      print('❌ Erro ao salvar dados do usuário: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> userDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }
}
