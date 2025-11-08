import 'package:flutter/material.dart';
import 'package:alanoapp/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;

  const AppLogo({
    Key? key,
    this.fontSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AlanoCrypto',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'FX',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGreen,
          ),
        ),
      ],
    );
  }
}
