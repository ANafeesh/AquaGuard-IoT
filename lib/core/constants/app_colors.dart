import 'package:flutter/material.dart';

/// AquaGuard Design System Color Palette
/// Curated modern water-themed palette: Deep Ocean, Cerulean Aqua, Emerald, Teal, with Slate dark mode.
class AppColors {
  // Primary Brand Colors
  static const Color primaryDeepOcean = Color(0xFF0369A1); // Deep Ocean Blue
  static const Color primaryAqua = Color(0xFF0EA5E9);      // Cerulean Aqua
  static const Color teal = Color(0xFF0D9488);             // Coastal Teal
  static const Color emerald = Color(0xFF059669);          // Emerald Green Accent
  static const Color lightAqua = Color(0xFFE0F2FE);
  static const Color darkOceanNavy = Color(0xFF0B192C);

  // Background Colors - Light Mode
  static const Color mainBackground = Color(0xFFF8FAFC);
  static const Color altLightAquaBg = Color(0xFFF0FDFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardSubtleBg = Color(0xFFF1F5F9);

  // Background Colors - Dark Mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkCardSubtleBg = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);

  // Text Colors - Light Mode
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color mutedText = Color(0xFF94A3B8);

  // Text Colors - Dark Mode
  static const Color darkPrimaryText = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFFCBD5E1);
  static const Color darkMutedText = Color(0xFF64748B);

  // Neutral Water Indicator Baseline Colors (Strictly neutral terminology)
  // Normal / Within Expected Range
  static const Color statusNormal = Color(0xFF0D9488);
  static const Color statusNormalBg = Color(0xFFCCFBF1);
  static const Color statusNormalDarkBg = Color(0xFF134E4A);

  // Unusual / Change Detected
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusWarningDarkBg = Color(0xFF78350F);

  // Requires Attention / Anomaly Spike
  static const Color statusAttention = Color(0xFFE11D48);
  static const Color statusAttentionBg = Color(0xFFFFE4E6);
  static const Color statusAttentionDarkBg = Color(0xFF881337);

  // No Recent Data / Offline Device
  static const Color statusNeutral = Color(0xFF64748B);
  static const Color statusNeutralBg = Color(0xFFF1F5F9);
  static const Color statusNeutralDarkBg = Color(0xFF1E293B);

  // Info / Device Telemetry
  static const Color statusInfo = Color(0xFF2563EB);
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

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
