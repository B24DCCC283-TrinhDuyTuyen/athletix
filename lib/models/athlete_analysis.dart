class Keypoint {
  final double x;
  final double y;
  final double conf;

  Keypoint({required this.x, required this.y, required this.conf});

  factory Keypoint.fromJson(Map<String, dynamic> json) {
    return Keypoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      conf: (json['conf'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PoseMetrics {
  final double? leftKneeAngle;
  final double? rightKneeAngle;
  final double? leftElbowAngle;
  final double? rightElbowAngle;
  final double? trunkAngle;
  final double? stridePixels;

  PoseMetrics({
    this.leftKneeAngle,
    this.rightKneeAngle,
    this.leftElbowAngle,
    this.rightElbowAngle,
    this.trunkAngle,
    this.stridePixels,
  });

  factory PoseMetrics.fromJson(Map<String, dynamic> json) {
    return PoseMetrics(
      leftKneeAngle: (json['left_knee_angle'] as num?)?.toDouble(),
      rightKneeAngle: (json['right_knee_angle'] as num?)?.toDouble(),
      leftElbowAngle: (json['left_elbow_angle'] as num?)?.toDouble(),
      rightElbowAngle: (json['right_elbow_angle'] as num?)?.toDouble(),
      trunkAngle: (json['trunk_angle'] as num?)?.toDouble(),
      stridePixels: (json['stride_pixels'] as num?)?.toDouble(),
    );
  }
}

class Athlete {
  final List<double> bbox;
  final PoseMetrics metrics;
  final List<String> feedbacks;
  final Map<String, Keypoint> keypoints;

  Athlete({
    required this.bbox,
    required this.metrics,
    required this.feedbacks,
    required this.keypoints,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    final rawKeypoints = json['keypoints'] as Map<String, dynamic>? ?? {};
    final kps = <String, Keypoint>{};
    rawKeypoints.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        kps[key] = Keypoint.fromJson(val);
      }
    });

    final rawFeedbacks = json['feedbacks'] as List<dynamic>? ?? [];

    return Athlete(
      bbox: (json['bbox'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      metrics: PoseMetrics.fromJson(json['metrics'] as Map<String, dynamic>? ?? {}),
      feedbacks: rawFeedbacks.map((e) => e.toString()).toList(),
      keypoints: kps,
    );
  }
}

class AnalysisResult {
  final bool success;
  final int numAthletes;
  final List<Athlete> athletes;
  final String annotatedImageBase64;
  final DateTime timestamp;

  AnalysisResult({
    required this.success,
    required this.numAthletes,
    required this.athletes,
    required this.annotatedImageBase64,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawAthletes = json['athletes'] as List<dynamic>? ?? [];
    return AnalysisResult(
      success: json['success'] as bool? ?? false,
      numAthletes: json['num_athletes'] as int? ?? 0,
      athletes: rawAthletes
          .map((e) => Athlete.fromJson(e as Map<String, dynamic>))
          .toList(),
      annotatedImageBase64: json['annotated_image_base64'] as String? ?? '',
      timestamp: DateTime.now(),
    );
  }
}
