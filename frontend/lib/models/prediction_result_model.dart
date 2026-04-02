/// Model for prediction result from YOLO inference
class PredictionResult {
  final int classId;
  final String className;
  final double confidence;

  // Dual prediction fields
  final bool isDualPrediction;
  final PredictionResult? alternativeResult;
  final String? decision;

  PredictionResult({
    required this.classId,
    required this.className,
    required this.confidence,
    this.isDualPrediction = false,
    this.alternativeResult,
    this.decision,
  });

  /// Factory constructor to create instance from JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Handle dual prediction response
    if (json['dual_prediction'] == true && json['primary'] != null) {
      return PredictionResult(
        classId: json['primary']['class_id'] ?? 0,
        className: json['primary']['class_name'] ?? 'Unknown',
        confidence: (json['primary']['confidence'] ?? 0.0).toDouble(),
        isDualPrediction: true,
        alternativeResult: json['alternative'] != null
            ? PredictionResult._fromSinglePrediction(json['alternative'])
            : null,
        decision: json['decision'],
      );
    }

    // Handle single prediction response
    return PredictionResult(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isDualPrediction: false,
    );
  }

  /// Private factory for alternative predictions (no dual prediction nesting)
  factory PredictionResult._fromSinglePrediction(Map<String, dynamic> json) {
    return PredictionResult(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isDualPrediction: false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    if (isDualPrediction && alternativeResult != null) {
      return {
        'dual_prediction': true,
        'primary': {
          'class_id': classId,
          'class_name': className,
          'confidence': confidence,
        },
        'alternative': {
          'class_id': alternativeResult!.classId,
          'class_name': alternativeResult!.className,
          'confidence': alternativeResult!.confidence,
        },
        'decision': decision,
      };
    }

    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }

  /// Create a new PredictionResult selecting the alternative (for when user chooses alternative)
  PredictionResult selectAlternative() {
    if (alternativeResult != null) {
      return alternativeResult!;
    }
    return this;
  }
}
