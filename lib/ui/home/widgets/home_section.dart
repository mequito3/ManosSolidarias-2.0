import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Generic section wrapper used across the home tabs to keep typography and
/// spacing consistent between campaigns and organizaciones.
class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final sectionPadding = padding ?? const EdgeInsets.only(bottom: 28);
    final effectiveColor = iconColor ?? AppColors.bluePrimary;

    return Padding(
      padding: sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 18),
                ),
                const SizedBox(width: 10),
              ] else ...[
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
