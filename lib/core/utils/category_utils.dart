import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryUtils {
  static IconData icon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'health':
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'rent':
        return Icons.home_outlined;
      case 'salary':
        return Icons.work_outline_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  static Color color(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transport':
        return const Color(0xFF4ECDC4);
      case 'shopping':
        return const Color(0xFFFFE66D);
      case 'entertainment':
        return const Color(0xFFA78BFA);
      case 'utilities':
        return const Color(0xFF34D399);
      case 'health':
      case 'healthcare':
        return const Color(0xFFFF8C5A);
      case 'education':
        return const Color(0xFF60A5FA);
      default:
        return AppColors.textSecondary;
    }
  }
}