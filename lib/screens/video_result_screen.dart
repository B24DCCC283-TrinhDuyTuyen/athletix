import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../models/video_analysis.dart';
import '../widgets/metric_card.dart';
import '../widgets/video_time_series_chart.dart';
import '../widgets/feedback_card.dart';

class VideoResultScreen extends StatelessWidget {
  final VideoAnalysisResult result;

  const VideoResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = result.summary;
    final videoFullUrl = ApiConstants.getMediaUrl(result.videoUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Tích Video Điền Kinh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner tổng quan xử lý video
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.videocam_outlined, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text('VIDEO ĐÃ XỬ LÝ AI', style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${result.processingFps.toStringAsFixed(0)} FPS',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCol('Thời lượng', '${result.durationSeconds}s'),
                      _buildInfoCol('Tổng khung hình', '${result.totalFrames} frames'),
                      _buildInfoCol('Số bước đo', '${summary.stepCount ?? 0} bước'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Link video đã render HUD khung xương
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            videoFullUrl,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Thẻ điểm nhấn Cadence (Nhịp bước SPM)
            if (summary.cadenceSpm != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (summary.cadenceSpm! >= 165 && summary.cadenceSpm! <= 190)
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.warning.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.speed, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NHỊP BƯỚC CHẠY (CADENCE)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${summary.cadenceSpm}',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('SPM (bước/phút)', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mức lý tưởng cho chạy hiệu quả: 165 - 185 SPM',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // 3. Lưới các chỉ số động học toàn chu kỳ
            Text('Các chỉ số chu kỳ bước chạy', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: [
                MetricCard(
                  title: 'Độ Duỗi Gối Max',
                  value: summary.maxKneeExtension,
                  standardMin: 155,
                  standardMax: 175,
                  icon: Icons.open_in_full,
                ),
                MetricCard(
                  title: 'Độ Co Gối Lăng',
                  value: summary.minKneeFlexion,
                  standardMin: 45,
                  standardMax: 75,
                  icon: Icons.close_fullscreen,
                ),
                MetricCard(
                  title: 'Độ Nghiêng Thân TB',
                  value: summary.avgTrunkAngle,
                  standardMin: 8,
                  standardMax: 18,
                  icon: Icons.accessibility_new,
                ),
                MetricCard(
                  title: 'Góc Khuỷu Tay TB',
                  value: summary.avgElbowAngle,
                  standardMin: 80,
                  standardMax: 105,
                  icon: Icons.sports,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. Biểu đồ đường chuỗi thời gian (Gait Cycle Line Chart)
            VideoTimeSeriesChart(timeSeries: result.timeSeries),

            const SizedBox(height: 20),

            // 5. Lời khuyên HLV AI
            FeedbackCard(feedbacks: result.feedbacks),

            const SizedBox(height: 24),

            // Nút quay lại
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Phân tích video/ảnh khác'),
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
