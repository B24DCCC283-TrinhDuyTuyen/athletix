import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class FeedbackCard extends StatelessWidget {
  final List<String> feedbacks;

  const FeedbackCard({super.key, required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Nhận xét từ Huấn Luyện Viên AI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...feedbacks.map(
            (fb) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.arrow_right,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fb,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
