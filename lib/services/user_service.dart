import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<UserModel?> getUserStream(String userId) {
    print('🔵 UserService.getUserStream() - userId: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          print('📄 getUserStream snapshot recebido - exists: ${doc.exists}');
          if (!doc.exists) {
            print('⚠️ getUserStream: documento não existe');
            return null;
          }
          try {
            final user = UserModel.fromFirestore(doc);
            print('✅ getUserStream: UserModel criado - ${user.displayName}');
            return user;
          } catch (e) {
            print('❌ getUserStream: Erro ao criar UserModel: $e');
            rethrow;
          }
        })
        .handleError((error) {
          print('❌ getUserStream handleError: $error');
          throw error;
        });
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  Future<bool> updateUser({
    required String userId,
    String? displayName,
    String? bio,
    String? photoURL,
    String? phone,
    String? telegram,
    String? accountId,
    String? broker,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (phone != null) updates['phone'] = phone;
      if (telegram != null) updates['telegram'] = telegram;
      if (accountId != null) updates['accountId'] = accountId;
      if (broker != null) updates['broker'] = broker;

      // Adiciona dados customizados se fornecidos
      if (data != null) {
        updates.addAll(data);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }

      return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  Future<String?> uploadProfileImage({
    File? imageFile,
    Uint8List? imageBytes,
    required String userId,
  }) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profiles/$userId/$fileName');

      final UploadTask uploadTask;

      if (kIsWeb) {
        // Na web, usar putData() com bytes
        if (imageBytes != null) {
          uploadTask = ref.putData(imageBytes);
        }
        else {
          return null;
        }
      } else {
        // No mobile, usar putFile()
        if (imageFile != null) {
          uploadTask = ref.putFile(imageFile);
        }
        else {
          return null;
        }
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem de perfil: $e');
      return null;
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      final postsCount = postsQuery.docs.length;

      final commentsQuery = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      final commentsCount = commentsQuery.docs.length;

      int likesCount = 0;
      for (var doc in postsQuery.docs) {
        final post = doc.data();
        final likedBy = post['likedBy'] as List?;
        if (likedBy != null) {
          likesCount += likedBy.length;
        }
      }

      return {
        'posts': postsCount,
        'comments': commentsCount,
        'likes': likesCount,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return {'posts': 0, 'comments': 0, 'likes': 0};
    }
  }

  Future<void> createOrUpdateUser(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      print('📸 DEBUG - photoURL do FirebaseAuth: ${user.photoURL}');

      if (userDoc.exists) {
        // Usuário já existe - atualizar lastLogin E photoURL se mudou
        final currentData = userDoc.data() as Map<String, dynamic>;
        final currentPhotoURL = currentData['photoURL'] as String?;

        final Map<String, dynamic> updates = {
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        };

        // Se a foto mudou, atualizar
        if (user.photoURL != null && user.photoURL != currentPhotoURL) {
          updates['photoURL'] = user.photoURL!;
          print('📸 Atualizando foto do usuário: ${user.photoURL}');
        }

        await userRef.update(updates);
        print('✅ Usuário existente atualizado: ${user.email}');
      } else {
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'Usuário',
          'photoURL': user.photoURL ?? '',
          'bio': '',
          'approved': false,
          'blocked': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'lastLogin': Timestamp.fromDate(DateTime.now()),
          'emailNotifications': true,
          'notificationPreferences': {
            'posts': true,
            'postsEmail': true,
            'signals': true,
            'signalsEmail': true,
            'mentions': true,
            'mentionsEmail': true,
            'chatMessages': false,
            'chatMessagesThrottle': {
              'enabled': true,
              'maxPerHour': 4,
              'batchInterval': 15,
            },
          },
        });
        print('✅ Novo usuário criado: ${user.email} - Precisa aprovação');
        print('📸 Foto do novo usuário: ${user.photoURL}');
      }
    } catch (e) {
      print('❌ Erro ao criar/atualizar usuário: $e');
      rethrow;
    }
  }

  Future<void> createUser(
    User firebaseUser, {
    String? displayName,
    String? phone,
    String? accountId,
    String? broker,
  }) async {
    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': displayName ?? firebaseUser.displayName ?? '',
        'photoURL': firebaseUser.photoURL ?? '',
        'phone': phone,
        'telegram': null,
        'country': 'Brasil',
        'tier': 'Free',
        'bio': '',
        'approved': false,
        'blocked': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'accountId': accountId,
        'broker': broker,
        'emailNotifications': true,
        'notificationPreferences': {
          'posts': true,
          'postsEmail': true,
          'signals': true,
          'signalsEmail': true,
          'mentions': true,
          'mentionsEmail': true,
          'chatMessages': false,
          'chatMessagesThrottle': {
            'enabled': true,
            'maxPerHour': 4,
            'batchInterval': 15,
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao criar usuário: $e');
    }
  }

  Future<bool> isUserApproved(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['approved'] ?? false;
    } catch (e) {
      print('Erro ao verificar aprovação: $e');
      return false;
    }
  }

  Future<List<UserModel>> searchApprovedUsers(String query, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('approved', isEqualTo: true)
          .get();

      List<UserModel> allUsers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      print('🔍 Total de usuários aprovados: ${allUsers.length}');
      if (allUsers.isNotEmpty) {
        print('📋 Usuários: ${allUsers.map((u) => u.displayName).join(", ")}');
      }

      if (query.isEmpty) {
        allUsers.sort((a, b) => a.displayName.compareTo(b.displayName));
        final result = allUsers.take(limit).toList();
        print('✅ Retornando ${result.length} usuários (sem filtro)');
        return result;
      }

      final queryLower = query.toLowerCase().trim();
      print('🔎 Buscando por: "$query"');

      final filteredUsers = allUsers.where((user) {
        if (user.displayName.isEmpty && user.email.isEmpty) return false;
        final nameLower = user.displayName.toLowerCase();
        final emailLower = user.email.toLowerCase();
        return nameLower.contains(queryLower) || emailLower.contains(queryLower);
      }).toList();

      print('✅ Encontrados ${filteredUsers.length} usuários para "$query"');
      if (filteredUsers.isNotEmpty) {
        print('📋 Resultados: ${filteredUsers.map((u) => u.displayName).join(", ")}');
      }

      filteredUsers.sort((a, b) {
        final aName = a.displayName.toLowerCase();
        final bName = b.displayName.toLowerCase();
        final aStarts = aName.startsWith(queryLower);
        final bStarts = bName.startsWith(queryLower);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return aName.compareTo(bName);
      });

      final result = filteredUsers.take(limit).toList();
      print('📤 Retornando ${result.length} usuários (limitado a $limit)');
      return result;
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }
}
