import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../models/user_model.dart';
import '../../../models/notification_preferences.dart';
import '../../../services/user_service.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_helper.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final effectiveUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🔵 ProfileScreen.build() - userId: $userId, effectiveUserId: $effectiveUserId');

    if (effectiveUserId == null) {
      debugPrint('❌ ProfileScreen: effectiveUserId é null');
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: UserService().getUserStream(effectiveUserId),
      builder: (context, snapshot) {
        debugPrint('🔵 ProfileScreen StreamBuilder - state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

        if (snapshot.hasError) {
          debugPrint('❌ ProfileScreen StreamBuilder error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erro ao carregar perfil', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint('⚠️ ProfileScreen: snapshot sem dados');
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_off, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text('Perfil não encontrado', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data!;
        final isOwnProfile = user.uid == FirebaseAuth.instance.currentUser?.uid;
        debugPrint('✅ ProfileScreen: user carregado - ${user.displayName}, isOwnProfile: $isOwnProfile');

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: !isOwnProfile ? AppBar(
            backgroundColor: AppTheme.appBarColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(user.displayName, style: const TextStyle(color: Colors.white)),
            elevation: 0,
          ) : null,
          body: _ProfileView(user: user, isOwnProfile: isOwnProfile),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _ProfileView({required this.user, required this.isOwnProfile});

  void _showEditProfileModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _SettingsModal(),
    );
  }

  Future<void> _logout(BuildContext context) async {
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

    if (confirm == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 _ProfileView.build() - user: ${user.displayName}, isOwnProfile: $isOwnProfile');

    return Container(
      color: AppTheme.backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isOwnProfile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.accentGreen),
                        onPressed: () => _showEditProfileModal(context, user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppTheme.accentGreen),
                        onPressed: () => _showSettings(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppTheme.accentGreen),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              _UserInfoCard(user: user, isOwnProfile: isOwnProfile),
              const SizedBox(height: 24),
              _InfoSection(user: user, isOwnProfile: isOwnProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _UserInfoCard({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 _UserInfoCard.build() - user: ${user.displayName}');

    final initials = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

    // Proteger DateFormat (pode falhar em produção web)
    String memberSince;
    try {
      memberSince = DateFormat('dd/MM/yyyy').format(user.createdAt);
    } catch (e) {
      debugPrint('❌ _UserInfoCard: Erro no DateFormat: $e');
      memberSince = '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL) : null,
            backgroundColor: AppTheme.accentGreen,
            child: user.photoURL.isEmpty ? Text(initials, style: const TextStyle(fontSize: 32, color: Colors.white)) : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOwnProfile)
                _StatusBadge(
                  icon: Icons.calendar_today,
                  label: 'Membro desde: $memberSince',
                  color: Colors.blue.shade300,
                ),
              if (isOwnProfile && user.isApproved)
                const SizedBox(width: 12),
              if (user.isApproved)
                _StatusBadge(
                  icon: Icons.verified,
                  label: 'Conta Verificada',
                  color: AppTheme.accentGreen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _InfoSection({required this.user, required this.isOwnProfile});

  // Helper para formatar data com fallback
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      debugPrint('❌ _InfoSection._formatDate erro: $e');
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 _InfoSection.build() - user: ${user.displayName}');

    final formattedPhone = user.phone != null && user.phone!.isNotEmpty ? user.phone! : 'Não informado';

    // Proteger chamada do AdminHelper (pode falhar em produção web)
    bool isAdmin = false;
    try {
      isAdmin = AdminHelper.isCurrentUserAdmin();
      debugPrint('🔐 _InfoSection: isAdmin = $isAdmin');
    } catch (e) {
      debugPrint('❌ _InfoSection: Erro ao verificar admin: $e');
      isAdmin = false;
    }

    final showAllData = isOwnProfile || isAdmin; // Admin vê tudo

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BADGE ADMIN - Mostra quando admin está vendo perfil de outro usuário
        if (isAdmin && !isOwnProfile) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade800, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'VISÃO ADMIN - Dados completos',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],

        const Text(
          'Informações Pessoais',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isTablet ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isTablet ? 4 : 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                // Nome - SEMPRE VISÍVEL
                _InfoTile(icon: Icons.person_outline, label: 'Nome Completo', value: user.displayName),

                // Email - próprio perfil OU admin
                if (showAllData)
                  _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email, canCopy: true),

                // Telefone - próprio perfil OU admin
                if (showAllData)
                  _InfoTile(icon: Icons.phone_outlined, label: 'Telefone', value: formattedPhone, canCopy: true),

                // Telegram - próprio perfil OU admin OU se preenchido
                if (showAllData || (user.telegram != null && user.telegram!.isNotEmpty))
                  _InfoTile(
                    icon: FontAwesomeIcons.telegram,
                    label: 'Telegram',
                    value: user.telegram ?? 'Não informado',
                    canCopy: user.telegram != null && user.telegram!.isNotEmpty,
                  ),

                // País - SEMPRE VISÍVEL
                _InfoTile(icon: Icons.flag_outlined, label: 'País', value: user.country),

                // Plano - SEMPRE VISÍVEL
                _InfoTile(icon: Icons.star_outline, label: 'Plano', value: user.tier),

                // ID da Conta - próprio perfil OU admin
                if (showAllData)
                  _InfoTile(
                    icon: Icons.numbers,
                    label: 'ID da Conta',
                    value: user.accountId ?? 'Não informado',
                    onTap: isOwnProfile ? () => _showEditAccountIdDialog(context, user) : null,
                    canCopy: user.accountId != null && user.accountId!.isNotEmpty,
                  ),

                // Corretora - próprio perfil OU admin
                if (showAllData)
                  _InfoTile(
                    icon: Icons.business,
                    label: 'Corretora',
                    value: user.broker ?? 'Não informada',
                    onTap: isOwnProfile ? () => _showEditBrokerDialog(context, user) : null,
                  ),

                // Data de criação - APENAS ADMIN vendo outro perfil
                if (isAdmin && !isOwnProfile)
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Membro desde',
                    value: _formatDate(user.createdAt),
                  ),

                // Status aprovação - APENAS ADMIN
                if (isAdmin && !isOwnProfile)
                  _InfoTile(
                    icon: user.isApproved ? Icons.verified : Icons.pending,
                    label: 'Status',
                    value: user.isApproved ? 'Aprovado' : 'Pendente',
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showEditAccountIdDialog(BuildContext context, UserModel user) {
    final controller = TextEditingController(text: user.accountId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Editar ID da Conta', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'ID da Conta',
            hintText: 'Digite o ID/número da sua conta',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppTheme.inputBackground,
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID da conta não pode ser vazio'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await UserService().updateUser(
                userId: user.uid,
                accountId: controller.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID da conta atualizado'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showEditBrokerDialog(BuildContext context, UserModel user) {
    String? selectedBroker = user.broker;
    final brokers = ['Vantage', 'Hantech', 'XM', 'Pocket Option', 'TV Markets'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text('Editar Corretora', style: TextStyle(color: AppTheme.textPrimary)),
          content: DropdownButtonFormField<String>(
            value: selectedBroker,
            decoration: InputDecoration(
              labelText: 'Corretora',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.inputBackground,
            ),
            dropdownColor: AppTheme.cardDark,
            style: const TextStyle(color: Colors.white),
            items: brokers.map((broker) {
              return DropdownMenuItem(value: broker, child: Text(broker));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedBroker = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedBroker == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione uma corretora'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await UserService().updateUser(
                  userId: user.uid,
                  broker: selectedBroker,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Corretora atualizada'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              child: const Text('Salvar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool canCopy;
  final VoidCallback? onTap;

  const _InfoTile({required this.icon, required this.label, required this.value, this.canCopy = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
          Icon(icon, color: AppTheme.accentGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value.replaceAll(RegExp(r'[() -]'), '')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copiado para a área de transferência!')),
                );
              },
            ),
        ],
      ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _telegramController;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _telegramController = TextEditingController(text: widget.user.telegram ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _photoURL = widget.user.photoURL;
  }

  Future<void> _pickAndUploadPhoto() async {
    final ImagePicker picker = ImagePicker();

    // Mostrar opções (incluindo remover foto)
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb) ...[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.accentGreen),
                title: const Text('Câmera', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.accentGreen),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_photoURL != null && _photoURL!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (result == null) return;

    // Remover foto
    if (result == 'remove') {
      await _removePhoto();
      return;
    }

    // Selecionar nova foto
    final source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Upload para Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      final bytes = await image.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      // Obter URL
      final photoURL = await ref.getDownloadURL();

      // Atualizar Firebase Auth
      await user.updatePhotoURL(photoURL);

      // Atualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': photoURL});

      setState(() {
        _photoURL = photoURL;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _isUploadingPhoto = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Tentar deletar do Storage (pode falhar se não existir)
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg');
        await ref.delete();
      } catch (_) {
        // Ignorar erro se arquivo não existir
      }

      // Remover URL do Firebase Auth
      await user.updatePhotoURL(null);

      // Remover URL do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': ''});

      setState(() {
        _photoURL = '';
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto removida com sucesso!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final success = await UserService().updateUser(
      userId: widget.user.uid,
      displayName: _nameController.text.trim(),
      phone: phone.isNotEmpty ? phone : null,
      telegram: _telegramController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Perfil atualizado com sucesso!' : 'Erro ao atualizar perfil.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.user.displayName.isNotEmpty
        ? widget.user.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.inputBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),

                // Foto de perfil editável
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _photoURL != null && _photoURL!.isNotEmpty
                            ? CachedNetworkImageProvider(_photoURL!)
                            : null,
                        backgroundColor: AppTheme.accentGreen,
                        child: _photoURL == null || _photoURL!.isEmpty
                            ? Text(initials, style: const TextStyle(fontSize: 36, color: Colors.white))
                            : null,
                      ),
                      if (_isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentGreen,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.inputBackground, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque para alterar a foto',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  validator: (value) => (value == null || value.trim().length < 3) ? 'Nome deve ter no mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (com código do país)',
                    hintText: 'Ex: +55 11 98765-4321',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telegramController,
                  decoration: const InputDecoration(labelText: 'Telegram (Opcional)', hintText: '@usuario'),
                   validator: (value) {
                    if (value != null && value.isNotEmpty && !value.startsWith('@')) {
                      return 'Usuário do Telegram deve começar com @';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsModal extends StatefulWidget {
  const _SettingsModal();

  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  bool _is2FAEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _is2FAEnabled = doc.data()?['twoFactorEnabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _is2FAEnabled = value);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'twoFactorEnabled': value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Verificação por email ativada'
                  : 'Verificação por email desativada',
            ),
            backgroundColor: value ? AppTheme.accentGreen : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _is2FAEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar configuração'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotificationSettings() {
    final prefsService = NotificationPreferencesService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<NotificationPreferences>(
        stream: prefsService.getPreferencesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentGreen,
                ),
              ),
            );
          }

          final prefs = snapshot.data!;

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.accentGreen.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.accentGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notificações',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Configure o que você quer receber',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationToggle(
                          title: 'Posts do Alano',
                          subtitle: 'Notificar quando Alano publicar novo conteúdo',
                          icon: Icons.article,
                          value: prefs.posts,
                          onChanged: (value) {
                            prefsService.updateSinglePreference('posts', value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationToggle(
                          title: 'Novos Sinais',
                          subtitle: 'Receber alertas de sinais de trading',
                          icon: Icons.show_chart,
                          value: prefs.signals,
                          onChanged: (value) {
                            prefsService.updateSinglePreference('signals', value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationToggle(
                          title: 'Menções no Chat',
                          subtitle: 'Sempre ativo (não configurável)',
                          icon: Icons.alternate_email,
                          value: true,
                          onChanged: null,
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationToggle(
                          title: 'Mensagens do Chat',
                          subtitle: 'Notificações instantâneas com agrupamento',
                          icon: Icons.chat_bubble_outline,
                          value: prefs.chatMessages,
                          onChanged: (value) {
                            if (value) {
                              _showChatMessagesWarning(() {
                                prefsService.updateSinglePreference(
                                  'chatMessages',
                                  value,
                                );
                              });
                            } else {
                              prefsService.updateSinglePreference(
                                'chatMessages',
                                value,
                              );
                            }
                          },
                          warning: null,
                        ),
                        if (prefs.chatMessages) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppTheme.accentGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ativo com Agrupamento',
                                      style: TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Notificações instantâneas ativadas.\n1 notificação mostra contador de novas mensagens.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool)? onChanged,
    String? warning,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.accentGreen,
                activeTrackColor: AppTheme.accentGreen.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showChatMessagesWarning(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: AppTheme.accentGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Notificações do Chat',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ative para receber notificações instantâneas de todas as mensagens do chat.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentGreen.withAlpha(76),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Sistema inteligente de agrupamento:',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Notificações se atualizam automaticamente\n'
                    '• 1 notificação mostra contador de mensagens\n'
                    '• Não gera spam no celular\n'
                    '• Funciona com app aberto ou fechado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Se desativado:',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Resumo por email 2x ao dia (9h e 17h)\n'
              '• Você ainda verá o badge no app',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Manter Desativado',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ativar Notificações',
              style: TextStyle(
                color: AppTheme.backgroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              Icon(Icons.settings, size: 28, color: AppTheme.accentGreen),
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

          InkWell(
            onTap: _showNotificationSettings,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerenciar preferências de notificação',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.dark_mode, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tema escuro',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Fixado',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verificação por email',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código de segurança ao fazer login',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _is2FAEnabled,
                    onChanged: _toggle2FA,
                    activeColor: AppTheme.accentGreen,
                    activeTrackColor: AppTheme.accentGreen.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
