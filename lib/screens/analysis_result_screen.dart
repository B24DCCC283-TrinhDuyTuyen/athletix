import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/athlete_analysis.dart';
import '../widgets/metric_card.dart';
import '../widgets/angle_bar_chart.dart';
import '../widgets/feedback_card.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  int _selectedAthleteIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final athletes = widget.result.athletes;
    final currentAthlete = athletes.isNotEmpty && _selectedAthleteIndex < athletes.length
        ? athletes[_selectedAthleteIndex]
        : null;

    // Giải mã ảnh Base64
    ImageProvider? imageProvider;
    if (widget.result.annotatedImageBase64.isNotEmpty) {
      try {
        final b64String = widget.result.annotatedImageBase64.replaceFirst(
          RegExp(r'data:image/[^;]+;base64,'),
          '',
        );
        imageProvider = MemoryImage(base64Decode(b64String));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Phân Tích Kỹ Thuật'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: athletes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warning),
                    const SizedBox(height: 16),
                    Text(
                      'Không phát hiện thấy vận động viên',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vui lòng chụp lại bức ảnh thấy rõ toàn thân người chạy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ảnh hiển thị khung xương AI
                  if (imageProvider != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image(
                            image: imageProvider,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 280,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'YOLO11-Pose AI',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 2. Bộ chọn vận động viên (nếu phát hiện nhiều người)
                  if (athletes.length > 1) ...[
                    Text(
                      'Chọn vận động viên (${athletes.length}):',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(athletes.length, (idx) {
                          final isSelected = idx == _selectedAthleteIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('VĐV #${idx + 1}'),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              onSelected: (_) {
                                setState(() => _selectedAthleteIndex = idx);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (currentAthlete != null) ...[
                    // 3. Lưới các chỉ số góc độ
                    Text(
                      'Các chỉ số chuyển động cơ thể',
                      style: theme.textTheme.titleLarge,
                    ),
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
                          title: 'Gối Trái',
                          value: currentAthlete.metrics.leftKneeAngle,
                          standardMin: 140,
                          standardMax: 165,
                          icon: Icons.directions_run,
                        ),
                        MetricCard(
                          title: 'Gối Phải',
                          value: currentAthlete.metrics.rightKneeAngle,
                          standardMin: 140,
                          standardMax: 165,
                          icon: Icons.directions_run,
                        ),
                        MetricCard(
                          title: 'Độ Nghiêng Thân',
                          value: currentAthlete.metrics.trunkAngle,
                          standardMin: 8,
                          standardMax: 18,
                          icon: Icons.accessibility_new,
                        ),
                        MetricCard(
                          title: 'Khuỷu Tay Phải',
                          value: currentAthlete.metrics.rightElbowAngle,
                          standardMin: 80,
                          standardMax: 105,
                          icon: Icons.sports,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 4. Biểu đồ thanh fl_chart
                    AngleBarChart(metrics: currentAthlete.metrics),

                    const SizedBox(height: 20),

                    // 5. Nhận xét Huấn luyện viên AI
                    FeedbackCard(feedbacks: currentAthlete.feedbacks),

                    const SizedBox(height: 30),
                  ],

                  // Nút phân tích ảnh mới
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Phân tích ảnh khác'),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
