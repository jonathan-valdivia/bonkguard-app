import 'package:flutter/material.dart';

// Colors
class AppColors {
  // Main brand colors
  static const primary = Color(0xFF1B263B); // deep navy
  static const primaryDark = Color(0xFF0D1B2A);
  static const accent = Color(0xFFF4A261); // warm orange

  // Neutrals
  static const background = Color(0xFFF8F9FC);
  static const surface = Colors.white;

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
}

// Logo
class BonkGuardLogo extends StatelessWidget {
  const BonkGuardLogo({
    super.key,
    this.fontSize = 20,
    this.onLightBackground = false,
  });

  final double fontSize;
  final bool onLightBackground;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );

    final guardColor = onLightBackground ? AppColors.textPrimary : Colors.white;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Bonk',
            style: baseStyle.copyWith(color: AppColors.accent),
          ),
          TextSpan(
            text: 'Guard',
            style: baseStyle.copyWith(color: guardColor),
          ),
        ],
      ),
    );
  }
}
