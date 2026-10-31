import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceVariant = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF111111);
  static const Color cardElevated = Color(0xFF1C1C1C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF444444);

  // Borders
  static const Color border = Color(0x33FFFFFF);
  static const Color borderBright = Color(0x66FFFFFF);
  static const Color borderSubtle = Color(0x1AFFFFFF);

  // Icons
  static const Color icon = Color(0xFFFFFFFF);
  static const Color iconSecondary = Color(0xFFAAAAAA);

  // Accent (white shades only)
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentMuted = Color(0xFFCCCCCC);

  // Overlay
  static const Color overlay = Color(0x80000000);

  // Priority levels (grayscale)
  static const Color priorityHigh = Color(0xFFFFFFFF);
  static const Color priorityMedium = Color(0xFFAAAAAA);
  static const Color priorityLow = Color(0xFF666666);

  // Shimmer
  static const Color shimmerBase = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);
}
