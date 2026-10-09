import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/analysis_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  double _conf = 0.35;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (file != null) {
        final notifier = ref.read(analysisProvider.notifier);
        await notifier.analyzeImage(file, conf: _conf);

        final state = ref.read(analysisProvider);
        if (state.result != null && mounted) {
          context.push('/result', extra: state.result);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );

      if (file != null) {
        final notifier = ref.read(analysisProvider.notifier);
        await notifier.analyzeVideo(file, conf: _conf, maxDuration: 30);

        final state = ref.read(analysisProvider);
        if (state.videoResult != null && mounted) {
          context.push('/video-result', extra: state.videoResult);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(analysisProvider);
    final serverStatus = ref.watch(serverStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text('ATHLETIX', style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 1.2)),
          ],
        ),
        actions: [
          // Trạng thái server AI
          serverStatus.when(
            data: (online) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (online ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (online ? AppColors.success : AppColors.danger).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: online ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    online ? 'AI Online' : 'AI Offline',
                    style: TextStyle(
                      color: online ? AppColors.success : AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOLO11-POSE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Phân Tích Ảnh & Video',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Phân Tích Động Tác\n& Nhịp Chạy Điền Kinh',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trích xuất 17 điểm khớp xương, tính nhịp bước (Cadence SPM), chu kỳ gối và độ nghiêng thân người.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Phân tích ảnh
                Text('Phân tích Ảnh (Tư thế chụp)', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Chụp Ảnh',
                        subtitle: 'Từ camera máy',
                        color: AppColors.primary,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Thư Viện Ảnh',
                        subtitle: 'Chọn ảnh có sẵn',
                        color: AppColors.secondary,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Phân tích video (Tính năng nâng cao)
                Row(
                  children: [
                    Text('Phân tích Video (Chuỗi chuyển động)', style: theme.textTheme.titleLarge),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.videocam_rounded,
                        title: 'Quay Video',
                        subtitle: 'Tối đa 30s',
                        color: AppColors.accent,
                        onTap: () => _pickVideo(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.video_library_rounded,
                        title: 'Tải Video Lên',
                        subtitle: 'MP4 / MOV / AVI',
                        color: Colors.orangeAccent,
                        onTap: () => _pickVideo(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Tinh chỉnh độ nhạy (Confidence Slider)
                Container(
                  padding: const EdgeInsets.all(16),
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
                          const Text(
                            'Độ nhạy nhận diện AI (conf):',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _conf.toStringAsFixed(2),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _conf,
                        min: 0.1,
                        max: 0.9,
                        divisions: 16,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.surfaceLight,
                        onChanged: (val) {
                          setState(() => _conf = val);
                        },
                      ),
                      const Text(
                        'Kéo thấp (0.2-0.3) nếu ảnh/video quay xa; kéo cao (0.5) nếu hình ảnh rõ nét.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // 5. Lỗi nếu có
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 6. Lịch sử phân tích Video
                if (state.videoHistory.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Lịch sử phân tích Video', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...state.videoHistory.map((vHist) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: Icon(Icons.videocam, color: AppColors.accent),
                          ),
                          title: Text('Video: ${vHist.summary.cadenceSpm ?? "--"} SPM (${vHist.durationSeconds}s)'),
                          subtitle: Text(
                            '${vHist.totalFrames} frames - ${vHist.processingFps.toStringAsFixed(0)} FPS AI',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () {
                            context.push('/video-result', extra: vHist);
                          },
                        ),
                      )),
                ],

                // 7. Lịch sử phân tích Ảnh
                if (state.history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Lịch sử phân tích Ảnh', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...state.history.map((hist) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: Icon(Icons.directions_run, color: AppColors.primary),
                          ),
                          title: Text('Phân tích ${hist.numAthletes} vận động viên'),
                          subtitle: Text(
                            '${hist.timestamp.hour.toString().padLeft(2, '0')}:${hist.timestamp.minute.toString().padLeft(2, '0')} - Hoàn thành',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () {
                            context.push('/result', extra: hist);
                          },
                        ),
                      )),
                ],
              ],
            ),
          ),

          // Loading overlay cho Ảnh
          if (state.isLoading)
            _buildLoadingOverlay(
              title: 'AI đang phân tích khung xương...',
              subtitle: 'Trích xuất 17 điểm khớp & tính góc độ',
            ),

          // Loading overlay cho Video
          if (state.isVideoProcessing)
            _buildLoadingOverlay(
              title: 'GPU đang phân tích video điền kinh...',
              subtitle: 'Xử lý từng khung hình, tính Cadence & vẽ HUD',
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay({required String title, required String subtitle}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
