import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors: Calm Blue
  static const Color primary = Color(0xFF2B7FE8);
  static const Color primaryLight = Color(0xFF5BA4F0);
  static const Color primarySurface = Color(0xFFE8F2FF);

  // Status
  static const Color done = Color(0xFF34C78A);       // taken
  static const Color missed = Color(0xFFFF6B6B);     // missed
  static const Color pending = Color(0xFFF9A825);    // pending
  static const Color skipped = Color(0xFF9E9E9E);    // skipped

  // Neutral Colors
  static const Color grey100 = Color(0xFFF5F7FA);
  static const Color grey200 = Color(0xFFE9ECF2);
  static const Color grey400 = Color(0xFFB0B8C8);
  static const Color grey600 = Color(0xFF6B7585);
  static const Color grey900 = Color(0xFF1A1F2E);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1F2E);
  static const Color textSecondary = Color(0xFF6B7585);
  static const Color textHint = Color(0xFFB0B8C8);
}