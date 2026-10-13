import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AquaGuard Premium Typography Hierarchy
/// Crisp, modern typography engineered for mobile clarity, high-contrast field readability,
/// and native iOS / Android system font rendering.
class AppTypography {
  static const List<String> fontFallbacks = [
    'SF Pro Display',
    'SF Pro Text',
    '-apple-system',
    'BlinkMacSystemFont',
    'Inter',
    'Roboto',
    'Segoe UI',
    'sans-serif',
  ];

  // Page titles: 24–28px, Bold / Heavy
  static const TextStyle largeTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.6,
    height: 1.2,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkLargeTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w800,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.6,
    height: 1.2,
    fontFamilyFallback: fontFallbacks,
  );

  // Section heading: 18–20px, Bold
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 18.5,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.35,
    height: 1.25,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkSectionHeading = TextStyle(
    fontSize: 18.5,
    fontWeight: FontWeight.w700,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.35,
    height: 1.25,
    fontFamilyFallback: fontFallbacks,
  );

  // Card title: 15–16px, SemiBold
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
    height: 1.3,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkCardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.2,
    height: 1.3,
    fontFamilyFallback: fontFallbacks,
  );

  // Body: 14px, Regular / Medium
  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    letterSpacing: -0.1,
    height: 1.45,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkBody = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.1,
    height: 1.45,
    fontFamilyFallback: fontFallbacks,
  );

  // Secondary text: 12.5px, Medium
  static const TextStyle secondary = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 0,
    height: 1.35,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkSecondary = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.darkSecondaryText,
    letterSpacing: 0,
    height: 1.35,
    fontFamilyFallback: fontFallbacks,
  );

  // Muted text: 11-12px
  static const TextStyle muted = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedText,
    letterSpacing: 0.05,
    height: 1.3,
    fontFamilyFallback: fontFallbacks,
  );

  // Observation Quote Note
  static const TextStyle observationNote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
    letterSpacing: -0.1,
    height: 1.45,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkObservationNote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.1,
    height: 1.45,
    fontFamilyFallback: fontFallbacks,
  );

  // Stat Numbers in Dashboard Cards
  static const TextStyle statNumber = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
    fontFamilyFallback: fontFallbacks,
  );

  // Measurement values: 28–32px, ExtraBold
  static const TextStyle measurementValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    height: 1.15,
    fontFamilyFallback: fontFallbacks,
  );

  static const TextStyle darkMeasurementValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.5,
    height: 1.15,
    fontFamilyFallback: fontFallbacks,
  );

  // Status Badge text: 11px, SemiBold
  static const TextStyle statusBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    fontFamilyFallback: fontFallbacks,
  );

  // Filter Chip text: 12px, SemiBold
  static const TextStyle chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFamilyFallback: fontFallbacks,
  );

  // Button text: 14.5px, SemiBold
  static const TextStyle button = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    fontFamilyFallback: fontFallbacks,
  );
}
