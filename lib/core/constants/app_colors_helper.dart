import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';

class AppColorsHelper {
  static AppColorsData getColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? AppColorsData.dark() : AppColorsData.light();
  }
}

class AppColorsData {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color error;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  AppColorsData({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.error,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  factory AppColorsData.light() {
    return AppColorsData(
      primary: AppColors.primary,
      primaryLight: AppColors.primaryLight,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.background,
      surface: AppColors.surface,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      border: AppColors.border,
    );
  }

  factory AppColorsData.dark() {
    return AppColorsData(
      primary: AppColorsDark.primary,
      primaryLight: AppColorsDark.primaryLight,
      secondary: AppColorsDark.secondary,
      error: AppColorsDark.error,
      background: AppColorsDark.background,
      surface: AppColorsDark.surface,
      textPrimary: AppColorsDark.textPrimary,
      textSecondary: AppColorsDark.textSecondary,
      border: AppColorsDark.border,
    );
  }
}
