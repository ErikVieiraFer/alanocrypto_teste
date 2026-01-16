import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final String? phone;
  final String? telegram;
  final String country;
  final String tier;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isApproved;
  final bool isAdmin;           // Se é administrador
  final String? accountId;      // ID/Número da conta
  final String? broker;         // Corretora

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    this.bio = '',
    this.phone,
    this.telegram,
    required this.country,
    required this.tier,
    required this.createdAt,
    required this.lastLogin,
    required this.isApproved,
    this.isAdmin = false,
    this.accountId,
    this.broker,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Usuário',
      photoURL: data['photoURL'] ?? '',
      bio: data['bio'] ?? '',
      phone: data['phone'],
      telegram: data['telegram'],
      country: data['country'] ?? 'Brasil',
      tier: data['tier'] ?? 'Free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: data['approved'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      accountId: data['accountId'],
      broker: data['broker'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'phone': phone,
      'telegram': telegram,
      'country': country,
      'tier': tier,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'approved': isApproved,
      'isAdmin': isAdmin,
      'accountId': accountId,
      'broker': broker,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? phone,
    String? telegram,
    String? country,
    String? tier,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isApproved,
    bool? isAdmin,
    String? accountId,
    String? broker,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      country: country ?? this.country,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isApproved: isApproved ?? this.isApproved,
      isAdmin: isAdmin ?? this.isAdmin,
      accountId: accountId ?? this.accountId,
      broker: broker ?? this.broker,
    );
  }
}

