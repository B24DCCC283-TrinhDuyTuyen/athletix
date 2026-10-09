import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/athlete_analysis.dart';
import '../models/video_analysis.dart';
import '../services/pose_analysis_service.dart';

// Service provider
final poseServiceProvider = Provider<PoseAnalysisService>((ref) {
  return PoseAnalysisService();
});

// Server status provider
final serverStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(poseServiceProvider);
  return await service.checkHealth();
});

// State class for Analysis (Ảnh & Video)
class AnalysisState {
  final bool isLoading;
  final bool isVideoProcessing;
  final String? error;
  final AnalysisResult? result;
  final VideoAnalysisResult? videoResult;
  final List<AnalysisResult> history;
  final List<VideoAnalysisResult> videoHistory;

  AnalysisState({
    this.isLoading = false,
    this.isVideoProcessing = false,
    this.error,
    this.result,
    this.videoResult,
    this.history = const [],
    this.videoHistory = const [],
  });

  AnalysisState copyWith({
    bool? isLoading,
    bool? isVideoProcessing,
    String? error,
    AnalysisResult? result,
    VideoAnalysisResult? videoResult,
    List<AnalysisResult>? history,
    List<VideoAnalysisResult>? videoHistory,
  }) {
    return AnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isVideoProcessing: isVideoProcessing ?? this.isVideoProcessing,
      error: error,
      result: result ?? this.result,
      videoResult: videoResult ?? this.videoResult,
      history: history ?? this.history,
      videoHistory: videoHistory ?? this.videoHistory,
    );
  }
}

// StateNotifier Provider
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final PoseAnalysisService _service;

  AnalysisNotifier(this._service) : super(AnalysisState());

  Future<void> analyzeImage(XFile file, {double conf = 0.35}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _service.analyzeImage(file, conf: conf);
      final updatedHistory = [res, ...state.history];
      state = state.copyWith(
        isLoading: false,
        result: res,
        history: updatedHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> analyzeVideo(XFile file, {double conf = 0.35, int maxDuration = 30}) async {
    state = state.copyWith(isVideoProcessing: true, error: null);
    try {
      final res = await _service.analyzeVideo(file, conf: conf, maxDuration: maxDuration);
      final updatedVidHistory = [res, ...state.videoHistory];
      state = state.copyWith(
        isVideoProcessing: false,
        videoResult: res,
        videoHistory: updatedVidHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isVideoProcessing: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = state.copyWith(result: null, videoResult: null, error: null, isLoading: false, isVideoProcessing: false);
  }
}

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final service = ref.watch(poseServiceProvider);
  return AnalysisNotifier(service);
});
