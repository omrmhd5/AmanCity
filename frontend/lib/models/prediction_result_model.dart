/// Model for prediction result from YOLO inference
class PredictionResult {
  final int classId;
  final String className;
  final double confidence;

  PredictionResult({
    required this.classId,
    required this.className,
    required this.confidence,
  });

  /// Factory constructor to create instance from JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }
}
