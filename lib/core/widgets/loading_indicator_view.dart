import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class LoadingIndicatorView extends StatelessWidget {
  final String message;

  const LoadingIndicatorView({
    super.key,
    this.message = 'Loading telemetry...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAqua),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
