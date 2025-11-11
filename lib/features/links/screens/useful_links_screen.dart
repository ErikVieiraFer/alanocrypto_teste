import 'package:flutter/material.dart';
import '../../../widgets/common/empty_state.dart';

class UsefulLinksScreen extends StatelessWidget {
  const UsefulLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.link_rounded,
      title: 'Links Úteis',
      message: 'Esta funcionalidade está em desenvolvimento\nEm breve disponível!',
    );
  }
}
