class DetectionEntity {
  final int id;
  final int? userId;
  final String? imageUrl;
  final String? ocrText;
  final String result;
  final double confidenceScore;
  final int? processingTimeMs;
  final String detectionMethod;
  final String? modelName;
  final DateTime createdAt;
  final List<AllergenResultEntity>? allergens;

  DetectionEntity({
    required this.id,
    this.userId,
    this.imageUrl,
    this.ocrText,
    required this.result,
    required this.confidenceScore,
    this.processingTimeMs,
    required this.detectionMethod,
    this.modelName,
    required this.createdAt,
    this.allergens,
  });
}

class AllergenResultEntity {
  final int allergenId;
  final String name;
  final String severity;
  final double confidenceScore;

  AllergenResultEntity({
    required this.allergenId,
    required this.name,
    required this.severity,
    required this.confidenceScore,
  });
}
