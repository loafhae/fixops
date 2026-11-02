import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'FIXOPS';
  static const String appSubtitle = 'Facility Issue Reporting & Maintenance';

  // Base API configuration
  // On Flutter Web: http://127.0.0.1:8000/api/v1
  // On Android Emulator: http://10.0.2.2:8000/api/v1
  // On Physical Device: Change to your host machine's LAN IP (e.g. http://192.168.1.X:8000/api/v1)
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  static String get serverRootUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}

class AppColors {
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color secondary = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color surface = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981); // Emerald
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityHigh = Color(0xFFF97316); // Orange
  static const Color priorityCritical = Color(0xFFEF4444); // Red

  // Status Colors
  static const Color statusSubmitted = Color(0xFF64748B); // Slate
  static const Color statusUnderReview = Color(0xFF8B5CF6); // Purple
  static const Color statusInProgress = Color(0xFF0284C7); // Blue
  static const Color statusResolved = Color(0xFF10B981); // Green
  static const Color statusCancelled = Color(0xFF94A3B8);
}

