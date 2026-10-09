class VideoSummary {
  final int? stepCount;
  final int? cadenceSpm;
  final double? avgTrunkAngle;
  final double? maxKneeExtension;
  final double? minKneeFlexion;
  final double? avgElbowAngle;

  VideoSummary({
    this.stepCount,
    this.cadenceSpm,
    this.avgTrunkAngle,
    this.maxKneeExtension,
    this.minKneeFlexion,
    this.avgElbowAngle,
  });

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    return VideoSummary(
      stepCount: json['step_count'] as int?,
      cadenceSpm: json['cadence_spm'] as int?,
      avgTrunkAngle: (json['avg_trunk_angle'] as num?)?.toDouble(),
      maxKneeExtension: (json['max_knee_extension'] as num?)?.toDouble(),
      minKneeFlexion: (json['min_knee_flexion'] as num?)?.toDouble(),
      avgElbowAngle: (json['avg_elbow_angle'] as num?)?.toDouble(),
    );
  }
}

class TimeSeriesPoint {
  final int frame;
  final double timestamp;
  final double? leftKneeAngle;
  final double? rightKneeAngle;
  final double? trunkAngle;

  TimeSeriesPoint({
    required this.frame,
    required this.timestamp,
    this.leftKneeAngle,
    this.rightKneeAngle,
    this.trunkAngle,
  });

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      frame: json['frame'] as int? ?? 0,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      leftKneeAngle: (json['left_knee_angle'] as num?)?.toDouble(),
      rightKneeAngle: (json['right_knee_angle'] as num?)?.toDouble(),
      trunkAngle: (json['trunk_angle'] as num?)?.toDouble(),
    );
  }
}

class VideoAnalysisResult {
  final bool success;
  final int totalFrames;
  final double durationSeconds;
  final double processingFps;
  final VideoSummary summary;
  final List<String> feedbacks;
  final List<TimeSeriesPoint> timeSeries;
  final String videoUrl;
  final String videoId;
  final DateTime timestamp;

  VideoAnalysisResult({
    required this.success,
    required this.totalFrames,
    required this.durationSeconds,
    required this.processingFps,
    required this.summary,
    required this.feedbacks,
    required this.timeSeries,
    required this.videoUrl,
    required this.videoId,
    required this.timestamp,
  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawFeedbacks = json['feedbacks'] as List<dynamic>? ?? [];
    final rawTimeSeries = json['time_series'] as List<dynamic>? ?? [];

    return VideoAnalysisResult(
      success: json['success'] as bool? ?? false,
      totalFrames: json['total_frames'] as int? ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      processingFps: (json['processing_fps'] as num?)?.toDouble() ?? 0.0,
      summary: VideoSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      feedbacks: rawFeedbacks.map((e) => e.toString()).toList(),
      timeSeries: rawTimeSeries
          .map((e) => TimeSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      videoUrl: json['video_url'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      timestamp: DateTime.now(),
    );
  }
}
