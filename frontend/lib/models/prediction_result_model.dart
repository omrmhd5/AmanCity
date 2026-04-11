/// Model for prediction result from YOLO inference
class PredictionResult {
  final int classId;
  final String className;
  final double confidence;

  // Dual prediction fields
  final bool isDualPrediction;
  final PredictionResult? alternativeResult;
  final String? decision;

  // No incident fields
  final bool noIncident;
  final String? noIncidentReason;

  PredictionResult({
    required this.classId,
    required this.className,
    required this.confidence,
    this.isDualPrediction = false,
    this.alternativeResult,
    this.decision,
    this.noIncident = false,
    this.noIncidentReason,
  });

  /// Factory constructor to create instance from JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Handle no incident response (Normal classification)
    if (json['no_incident'] == true) {
      return PredictionResult(
        classId: 0,
        className: 'Normal',
        confidence: 0.0,
        isDualPrediction: false,
        noIncident: true,
        noIncidentReason: json['reason'],
      );
    }

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

    // Handle single prediction response (supports both class_name and incident_type)
    String className = json['class_name'] ?? json['incident_type'] ?? 'Unknown';
    return PredictionResult(
      classId: json['class_id'] ?? 0,
      className: className,
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
    if (noIncident) {
      return {'no_incident': true, 'reason': noIncidentReason};
    }

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
