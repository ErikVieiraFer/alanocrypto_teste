import 'package:flutter/material.dart';
import '../../../widgets/common/empty_state.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.school_rounded,
      title: 'Cursos',
      message: 'Esta funcionalidade está em desenvolvimento\nEm breve disponível!',
    );
  }
}
