import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF1D6E5F);
  static const Color primaryDark = Color(0xFF15544A);
  static const Color primaryTint = Color(0xFFE7F1EF);
  
  // Backgrounds
  static const Color backgroundCanvas = Color(0xFFF5F9F7);
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
  static const Color statusRejected = Color(0xFFA4243B);

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return priorityCritical;
      case 'high': return priorityHigh;
      case 'medium': return priorityMedium;
      case 'low': default: return priorityLow;
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return statusSubmitted;
      case 'under_review': return statusUnderReview;
      case 'government_handling': return statusGovHandling;
      case 'released': return statusReleased;
      case 'interest_expressed': case 'in_progress': return statusInProgress;
      case 'resolved': return statusResolved;
      case 'rejected': return statusRejected;
      default: return statusSubmitted;
    }
  }

  /// For status badge pill foreground
  static Color statusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': case 'government_handling': case 'in_progress': case 'released': case 'interest_expressed':
        return const Color(0xFF15544A);
      case 'rejected':
        return const Color(0xFFA4243B);
      case 'under_review': case 'submitted':
        return const Color(0xFF48566A);
      default:
        return const Color(0xFF48566A);
    }
  }

  /// For status badge pill background
  static Color statusBadgeBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': case 'government_handling': case 'in_progress': case 'released': case 'interest_expressed':
        return const Color(0xFFE7F1EF);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'under_review': case 'submitted':
        return const Color(0xFFEEF0F2);
      default:
        return const Color(0xFFEEF0F2);
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
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1D6E5F),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF1D6E5F),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1D6E5F)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryTint,
        labelStyle: const TextStyle(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }
}
