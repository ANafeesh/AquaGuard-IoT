import 'package:flutter/material.dart';

/// AquaGuard Design System Color Palette
class AppColors {
  // Primary Brand Colors
  static const Color primaryDeepOcean = Color(0xFF075985);
  static const Color primaryAqua = Color(0xFF0891B2);
  static const Color teal = Color(0xFF0D9488);
  static const Color lightAqua = Color(0xFFE0F2FE);

  // Background Colors
  static const Color mainBackground = Color(0xFFF8FAFC);
  static const Color altLightAquaBg = Color(0xFFF0FDFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardSubtleBg = Color(0xFFF1F5F9);

  // Text Colors
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);

  // Status Colors (Adheres strictly to prototype guidelines)
  static const Color statusNormal = Color(0xFF16A34A);       // Healthy / Normal
  static const Color statusNormalBg = Color(0xFFDCFCE7);
  static const Color statusWarning = Color(0xFFF59E0B);      // Unusual / Warning
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusAttention = Color(0xFFDC2626);    // Requires Attention
  static const Color statusAttentionBg = Color(0xFFFEE2E2);
  static const Color statusInfo = Color(0xFF2563EB);         // Information
  static const Color statusInfoBg = Color(0xFFDBEAFE);

  // Border & Divider Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeepOcean, primaryAqua],
  );

  static const LinearGradient aquaTealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryAqua, teal],
  );

  static const LinearGradient cardSubtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0FDFA)],
  );
}
