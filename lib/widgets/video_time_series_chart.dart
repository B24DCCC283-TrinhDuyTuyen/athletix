import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../models/video_analysis.dart';

class VideoTimeSeriesChart extends StatelessWidget {
  final List<TimeSeriesPoint> timeSeries;

  const VideoTimeSeriesChart({super.key, required this.timeSeries});

  @override
  Widget build(BuildContext context) {
    if (timeSeries.isEmpty) {
      return const SizedBox.shrink();
    }

    final leftSpots = <FlSpot>[];
    final rightSpots = <FlSpot>[];

    for (final pt in timeSeries) {
      if (pt.leftKneeAngle != null) {
        leftSpots.add(FlSpot(pt.timestamp, pt.leftKneeAngle!));
      }
      if (pt.rightKneeAngle != null) {
        rightSpots.add(FlSpot(pt.timestamp, pt.rightKneeAngle!));
      }
    }

    final maxTime = timeSeries.last.timestamp > 0 ? timeSeries.last.timestamp : 10.0;

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
                'Biểu đồ chu kỳ gập gối (Gait Cycle)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
              ),
              Row(
                children: [
                  _buildLegend(AppColors.primary, 'Gối Trái'),
                  const SizedBox(width: 10),
                  _buildLegend(AppColors.secondary, 'Gối Phải'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxTime,
                minY: 40,
                maxY: 180,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 35,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surfaceLight.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (maxTime / 5).clamp(1.0, 10.0),
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toStringAsFixed(1)}s',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 35,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}°',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (leftSpots.isNotEmpty)
                    LineChartBarData(
                      spots: leftSpots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  if (rightSpots.isNotEmpty)
                    LineChartBarData(
                      spots: rightSpots,
                      isCurved: true,
                      color: AppColors.secondary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
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
