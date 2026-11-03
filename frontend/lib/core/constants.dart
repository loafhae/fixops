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
  // Brand Color Palette (#E00000, #FFA97B, #FFECCB, #9FED72)
  static const Color primary = Color(0xFFE00000); // Crimson Red
  static const Color secondary = Color(0xFFFFA97B); // Sunset Peach
  static const Color cream = Color(0xFFFFECCB); // Warm Cream / Sand
  static const Color accentLime = Color(0xFF9FED72); // Fresh Lime Green

  // Surfaces & Glass
  static const Color surface = Color(0xFFFFF9F2); // Warm tinted surface
  static const Color surfaceWarm = Color(0xFFFFECCB);
  static const Color card = Colors.white;
  static const Color glassWhite = Color(0xB8FFFFFF); // ~72% frosted white
  static const Color glassCardBg = Color(0xC7FFFFFF); // ~78% white
  static const Color glassBorder = Color(0xB3FFFFFF); // ~70% specular border
  static const Color glassDark = Color(0xD91E1310); // Frosted dark obsidian slate

  // Typography
  static const Color textMain = Color(0xFF241512); // Deep charcoal espresso
  static const Color textMuted = Color(0xFF7A6560); // Warm slate muted

  // Priority Colors
  static const Color priorityLow = Color(0xFF67CF34); // Fresh Lime-Green
  static const Color priorityMedium = Color(0xFFFFA97B); // Peach
  static const Color priorityHigh = Color(0xFFFF6433); // Vivid Coral
  static const Color priorityCritical = Color(0xFFE00000); // Palette Crimson

  // Status Colors
  static const Color statusSubmitted = Color(0xFF8D7C78); // Warm Slate
  static const Color statusUnderReview = Color(0xFFE00000); // Crimson Alert
  static const Color statusInProgress = Color(0xFFFFA97B); // Peach In-Progress
  static const Color statusResolved = Color(0xFF55C728); // Vibrant Lime
  static const Color statusCancelled = Color(0xFFA59B97);
}
