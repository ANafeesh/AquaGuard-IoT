import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AquaGuard Typography Hierarchy
/// Large, readable typography optimized for outdoor field readability and presentations.
class AppTypography {
  // Page titles: 24–28px, Bold
  static const TextStyle largeTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle darkLargeTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.5,
    height: 1.25,
  );

  // Section heading: 18–20px, SemiBold
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle darkSectionHeading = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // Card title: 15–17px, SemiBold
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle darkCardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.2,
    height: 1.35,
  );

  // Body: 14–15px, Regular
  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    letterSpacing: -0.1,
    height: 1.45,
  );

  static const TextStyle darkBody = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.1,
    height: 1.45,
  );

  // Secondary text: 12–13px, Regular / Medium
  static const TextStyle secondary = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle darkSecondary = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.darkSecondaryText,
    letterSpacing: 0,
    height: 1.4,
  );

  // Muted text: 11-12px
  static const TextStyle muted = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
    letterSpacing: 0.1,
    height: 1.3,
  );

  // Measurement values: 28–34px, Bold
  static const TextStyle measurementValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle darkMeasurementValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.darkPrimaryText,
    letterSpacing: -0.5,
    height: 1.15,
  );

  // Status Badge text: 11-12px, SemiBold
  static const TextStyle statusBadge = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Button text: 14-15px, SemiBold
  static const TextStyle button = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
