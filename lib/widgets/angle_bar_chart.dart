import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../models/athlete_analysis.dart';

class AngleBarChart extends StatelessWidget {
  final PoseMetrics metrics;

  const AngleBarChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final knee = metrics.rightKneeAngle ?? metrics.leftKneeAngle ?? 0.0;
    final elbow = metrics.rightElbowAngle ?? metrics.leftElbowAngle ?? 0.0;
    final trunk = metrics.trunkAngle ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ góc kỹ thuật',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              Row(
                children: [
                  _buildLegend(AppColors.primary, 'Thực tế'),
                  const SizedBox(width: 12),
                  _buildLegend(AppColors.secondary.withValues(alpha: 0.5), 'Chuẩn TB'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 180,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceLight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Thực tế' : 'Chuẩn';
                      return BarTooltipItem(
                        '$label: ${rod.toY.toStringAsFixed(1)}°',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 0:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Gối', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            );
                          case 1:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Tay', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            );
                          case 2:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Thân', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 45,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}°',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 45,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  // Cột 0: Gối (Knee) - Chuẩn TB: 155
                  _buildBarGroup(0, knee, 155),
                  // Cột 1: Tay (Elbow) - Chuẩn TB: 90
                  _buildBarGroup(1, elbow, 90),
                  // Cột 2: Thân (Trunk) - Chuẩn TB: 12
                  _buildBarGroup(2, trunk, 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double actual, double benchmark) {
    return BarChartGroupData(
      x: x,
      barsSpace: 6,
      barRods: [
        BarChartRodData(
          toY: actual,
          color: AppColors.primary,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: benchmark,
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
