class HazardResponse {
  HazardResponse({
    required this.finalHazard,
    required this.confidence,
    required this.severity,
    required this.recommendation,
    required this.detections,
  });

  final String finalHazard;
  final double confidence;
  final String severity;
  final String recommendation;
  final List<DetectionResult> detections;

  factory HazardResponse.fromJson(Map<String, dynamic> json) {
    final rawDetections = json['detections'] as List<dynamic>? ?? const [];

    return HazardResponse(
      finalHazard: json['finalHazard'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      severity: json['severity'] as String? ?? 'Unknown',
      recommendation: json['recommendation'] as String? ?? 'No recommendation available.',
      detections: rawDetections
          .whereType<Map<String, dynamic>>()
          .map(DetectionResult.fromJson)
          .toList(),
    );
  }
}

class DetectionResult {
  DetectionResult({
    required this.modelId,
    required this.classId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  final String modelId;
  final int classId;
  final String label;
  final double confidence;
  final BoundingBox boundingBox;

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      modelId: (json['modelId'] ?? json['model_id'] ?? 'unknown') as String,
      classId: (json['classId'] ?? json['class_id'] ?? 0) as int,
      label: json['label'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      boundingBox: BoundingBox.fromJson(
        json['bbox'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BoundingBox {
  const BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] as num?)?.toDouble() ?? 0,
      y1: (json['y1'] as num?)?.toDouble() ?? 0,
      x2: (json['x2'] as num?)?.toDouble() ?? 0,
      y2: (json['y2'] as num?)?.toDouble() ?? 0,
    );
  }
}
