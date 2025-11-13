import 'package:flutter/material.dart';

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.description,
    this.icon,
    this.assetPath,
    this.accentColor,
  }) : assert(icon != null || assetPath != null, 'Define icon or assetPath');

  final String title;
  final String description;
  final IconData? icon;
  final String? assetPath;
  final Color? accentColor;
}
