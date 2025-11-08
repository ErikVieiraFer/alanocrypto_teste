import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _editProfile(UserModel user) async {
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'displayName': nameController.text.trim(),
                'bio': bioController.text.trim(),
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final success = await _userService.updateUser(
        userId: user.uid,
        displayName: result['displayName'],
        bio: result['bio'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Perfil atualizado!' : 'Erro ao atualizar perfil',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeProfilePhoto(UserModel user) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String? imageUrl;

      if (kIsWeb) {
        // Na web, ler os bytes do XFile
        final Uint8List imageBytes = await image.readAsBytes();
        imageUrl = await _userService.uploadProfileImage(
          imageBytes: imageBytes,
          userId: user.uid,
        );
      } else {
        // No mobile, usar File normalmente
        imageUrl = await _userService.uploadProfileImage(
          imageFile: File(image.path),
          userId: user.uid,
        );
      }

      if (mounted) Navigator.pop(context);

      if (imageUrl != null) {
        final success = await _userService.updateUser(
          userId: user.uid,
          photoURL: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Foto atualizada!' : 'Erro ao atualizar foto',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao fazer upload da foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsModal(),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se userId foi passado, usa ele; senão usa o usuário logado
    final userId = widget.userId ?? _auth.currentUser?.uid;
    final isOwnProfile = userId == _auth.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: _userService.getUserStream(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Erro')),
              body: Center(child: Text('Erro ao carregar perfil: ${userSnapshot.error}')),
            );
          }

          final user = userSnapshot.data;

          if (user == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Não Encontrado')),
              body: const Center(child: Text('Este usuário não foi encontrado.')),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.appBarColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.appBarColor,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: user.photoURL.isNotEmpty
                                    ? CachedNetworkImageProvider(user.photoURL)
                                    : null,
                                child: user.photoURL.isEmpty
                                    ? Text(
                                        user.displayName[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 36),
                                      )
                                    : null,
                              ),
                              if (isOwnProfile)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _changeProfilePhoto(user),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(51),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (isOwnProfile) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editProfile(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showSettings,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.textPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Biografia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditBioDialog(context, user),
                                color: AppTheme.accentGreen,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.bio.isEmpty
                              ? 'Conte um pouco sobre você...'
                              : user.bio,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: user.bio.isEmpty
                                ? AppTheme.textPrimary.withValues(alpha: 0.4)
                                : AppTheme.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }

  void _showEditBioDialog(BuildContext context, UserModel user) {
    final bioController = TextEditingController(text: user.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.inputBackground,
        title: Text(
          'Editar Biografia',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: bioController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Conte um pouco sobre você...',
            hintStyle: TextStyle(
              color: AppTheme.textPrimary.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _userService.updateUser(
                userId: user.uid,
                data: {'bio': bioController.text},
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Biografia atualizada!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, size: 28, color: AppTheme.textPrimary),
              const SizedBox(width: 12),
              Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Tema fixado em modo escuro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fechar',
                style: TextStyle(color: AppTheme.accentGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}