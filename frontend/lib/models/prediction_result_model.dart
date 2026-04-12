/// Model for prediction result from YOLO inference
class PredictionResult {
  final int classId;
  final String className;
  final double confidence;
  final String? model; // Model source: 'crime', 'weapons', '7Classes'

  // Multiple prediction fields - support up to 3 selectable predictions
  final bool hasMultiplePredictions;
  final List<PredictionResult>? alternatives;

  // No incident fields
  final bool noIncident;
  final String? noIncidentReason;

  PredictionResult({
    required this.classId,
    required this.className,
    required this.confidence,
    this.model,
    this.hasMultiplePredictions = false,
    this.alternatives,
    this.noIncident = false,
    this.noIncidentReason,
  });

  /// Factory constructor to create instance from JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Handle no incident response
    if (json['no_incident'] == true) {
      return PredictionResult(
        classId: 0,
        className: 'Normal',
        confidence: 0.0,
        noIncident: true,
        noIncidentReason: json['reason'],
      );
    }

    // Handle multiple incidents - convert to selectable predictions
    if (json['incidents'] != null && json['incidents'] is List) {
      List<dynamic> incidentsList = json['incidents'];

      if (incidentsList.isNotEmpty) {
        // Parse all incidents as alternatives to choose from
        List<PredictionResult> predictions = [];

        for (var inc in incidentsList) {
          predictions.add(
            PredictionResult(
              classId: inc['class_id'] ?? 0,
              className: inc['incident_type'] ?? 'Unknown',
              confidence: (inc['confidence'] ?? 0.0).toDouble(),
              model: inc['model'],
              noIncident: false,
            ),
          );
        }

        // Sort by confidence (highest first)
        predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

        // Primary is first one (highest confidence)
        PredictionResult primary = predictions[0];
        List<PredictionResult>? alts = predictions.length > 1
            ? predictions.sublist(1)
            : null;

        return PredictionResult(
          classId: primary.classId,
          className: primary.className,
          confidence: primary.confidence,
          model: primary.model,
          hasMultiplePredictions: predictions.length > 1,
          alternatives: alts,
        );
      }
    }

    // Handle single prediction response
    String className = json['class_name'] ?? json['incident_type'] ?? 'Unknown';
    return PredictionResult(
      classId: json['class_id'] ?? 0,
      className: className,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      model: json['model'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    if (noIncident) {
      return {'no_incident': true, 'reason': noIncidentReason};
    }

    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }
}
