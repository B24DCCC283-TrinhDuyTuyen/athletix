import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final double standardMin;
  final double standardMax;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '°',
    required this.standardMin,
    required this.standardMax,
    required this.icon,
  });

  bool get isStandard {
    if (value == null) return false;
    return value! >= standardMin && value! <= standardMax;
  }

  Color get statusColor {
    if (value == null) return AppColors.textMuted;
    if (isStandard) return AppColors.success;
    final diff = (value! < standardMin)
        ? (standardMin - value!)
        : (value! - standardMax);
    return diff > 15 ? AppColors.danger : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value != null ? '${value!.toStringAsFixed(1)}$unit' : '--',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isStandard ? Icons.check_circle_outline : Icons.info_outline,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Chuẩn: ${standardMin.toInt()}°-${standardMax.toInt()}°',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
