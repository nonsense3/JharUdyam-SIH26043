import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF1D6E5F);
  static const Color primaryDark = Color(0xFF15544A);
  static const Color primaryTint = Color(0xFFE7F1EF);
  
  // Backgrounds
  static const Color backgroundCanvas = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Priority Colors
  static const Color priorityCritical = Color(0xFFA4243B);
  static const Color priorityHigh = Color(0xFFBE6218);
  static const Color priorityMedium = Color(0xFF3D6B94);
  static const Color priorityLow = Color(0xFF6B7A8C);

  // Status Colors
  static const Color statusSubmitted = Color(0xFF48566A);
  static const Color statusUnderReview = Color(0xFF3D6B94);
  static const Color statusGovHandling = Color(0xFF1D6E5F);
  static const Color statusReleased = Color(0xFF4B3F9E);
  static const Color statusInProgress = Color(0xFF4B3F9E);
  static const Color statusResolved = Color(0xFF15544A);

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
      default:
        return priorityLow;
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return statusSubmitted;
      case 'under_review':
        return statusUnderReview;
      case 'government_handling':
        return statusGovHandling;
      case 'released':
        return statusReleased;
      case 'interest_expressed':
      case 'in_progress':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      default:
        return statusSubmitted;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceCard,
      ),
      scaffoldBackgroundColor: backgroundCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryTint,
        labelStyle: const TextStyle(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
