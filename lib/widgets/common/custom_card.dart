import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.cardDark,
        borderRadius: AppTheme.defaultRadius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth ?? 1)
            : null,
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: padding ?? const EdgeInsets.all(AppTheme.paddingMedium),
      margin: margin ?? const EdgeInsets.only(bottom: AppTheme.gapMedium),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppTheme.defaultRadius,
              child: child,
            )
          : child,
    );
  }
}
