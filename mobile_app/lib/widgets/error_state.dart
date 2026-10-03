import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'primary_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Unable to load measurements',
    this.message = 'Please check your connection and try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.statusAttentionBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.statusAttention.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.wifi_tethering_error_rounded_outlined,
                size: 36,
                color: AppColors.statusAttention,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.secondary.copyWith(
                fontSize: 13.5,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}
