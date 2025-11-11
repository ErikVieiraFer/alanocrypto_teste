import 'package:flutter/material.dart';
import '../../../widgets/common/empty_state.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.business_center_rounded,
      title: 'Portfólio',
      message: 'Esta funcionalidade está em desenvolvimento\nEm breve disponível!',
    );
  }
}
