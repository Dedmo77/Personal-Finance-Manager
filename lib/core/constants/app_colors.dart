import 'package:flutter/material.dart';

// ─── Static light palette (kept for AppTheme) ────────────────────────────────
class AppColors {
  static const primary       = Color(0xFF4F46E5);
  static const primaryLight  = Color(0xFFEEF2FF);
  static const secondary     = Color(0xFF10B981);
  static const error         = Color(0xFFEF4444);
  static const background    = Color(0xFFF9FAFB);
  static const surface       = Colors.white;
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border        = Color(0xFFE5E7EB);

  /// Returns the correct color set for the current theme.
  /// Use `final c = AppColors.of(context);` in every build method.
  static AppColorSet of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorSet.dark()
        : AppColorSet.light();
  }
}

// ─── Static dark palette (kept for AppTheme) ─────────────────────────────────
class AppColorsDark {
  static const primary       = Color(0xFF6366F1);
  static const primaryLight  = Color(0xFF312E81);
  static const secondary     = Color(0xFF059669);
  static const error         = Color(0xFFF87171);
  static const background    = Color(0xFF0F172A);
  static const surface       = Color(0xFF1E293B);
  static const textPrimary   = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFFCBD5E1);
  static const border        = Color(0xFF334155);
}

// ─── Dynamic color set ────────────────────────────────────────────────────────
class AppColorSet {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color error;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const AppColorSet._({
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

  factory AppColorSet.light() => const AppColorSet._(
    primary:       AppColors.primary,
    primaryLight:  AppColors.primaryLight,
    secondary:     AppColors.secondary,
    error:         AppColors.error,
    background:    AppColors.background,
    surface:       AppColors.surface,
    textPrimary:   AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    border:        AppColors.border,
  );

  factory AppColorSet.dark() => const AppColorSet._(
    primary:       AppColorsDark.primary,
    primaryLight:  AppColorsDark.primaryLight,
    secondary:     AppColorsDark.secondary,
    error:         AppColorsDark.error,
    background:    AppColorsDark.background,
    surface:       AppColorsDark.surface,
    textPrimary:   AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    border:        AppColorsDark.border,
  );
}