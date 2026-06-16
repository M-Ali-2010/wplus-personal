import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF050510);
  static const surface = Color(0xFF0F0F1A);
  static const surfaceLight = Color(0xFF1A1A2E);
  static const card = Color(0xFF12121F);

  static const primary = Color(0xFFFF00FF);
  static const primaryDark = Color(0xFFCC00CC);
  static const secondary = Color(0xFF8A2BE2);
  static const accent = Color(0xFFFF1493);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C0);
  static const textMuted = Color(0xFF6B6B80);

  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFB300);
  static const error = Color(0xFFFF5252);
  static const live = Color(0xFFFF1744);

  static const gradientPrimary = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCard = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF12121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
