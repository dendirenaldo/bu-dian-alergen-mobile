import '../../domain/entities/detection_entity.dart';

class DetectionModel {
  final int id;
  final int userId;
  final String? imageUrl;
  final String? ocrText;
  final String result;
  final double confidenceScore;
  final int? processingTimeMs;
  final String detectionMethod;
  final DateTime createdAt;
  final List<AllergenResultModel>? detectionAllergens;

  DetectionModel({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.ocrText,
    required this.result,
    required this.confidenceScore,
    this.processingTimeMs,
    required this.detectionMethod,
    required this.createdAt,
    this.detectionAllergens,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DetectionModel(
      id: data['id'],
      userId: data['userId'],
      imageUrl: data['imageUrl'],
      ocrText: data['ocrText'],
      result: data['result'],
      confidenceScore: (data['confidenceScore'] as num).toDouble(),
      processingTimeMs: data['processingTimeMs'],
      detectionMethod: data['detectionMethod'],
      createdAt: DateTime.parse(data['createdAt']),
      detectionAllergens: data['detectionAllergens'] != null
          ? (data['detectionAllergens'] as List)
              .map((e) => AllergenResultModel.fromJson(e))
              .toList()
          : null,
    );
  }

  DetectionEntity toEntity() => DetectionEntity(
    id: id,
    userId: userId,
    imageUrl: imageUrl,
    ocrText: ocrText,
    result: result,
    confidenceScore: confidenceScore,
    processingTimeMs: processingTimeMs,
    detectionMethod: detectionMethod,
    createdAt: createdAt,
    allergens: detectionAllergens?.map((e) => e.toEntity()).toList(),
  );
}

class AllergenResultModel {
  final int allergenId;
  final String name;
  final String severityLevel;
  final double confidenceScore;

  AllergenResultModel({
    required this.allergenId,
    required this.name,
    required this.severityLevel,
    required this.confidenceScore,
  });

  factory AllergenResultModel.fromJson(Map<String, dynamic> json) {
    // Backend kirim relasi: { detectionId, allergenId, confidenceScore, allergen: { name, severityLevel } }.
    // ML/flat kirim: { allergenId?, name, severityLevel?, confidence }.
    final nested = json['allergen'] as Map<String, dynamic>?;
    return AllergenResultModel(
      allergenId: (json['allergenId'] ?? nested?['id'] ?? 0) as int,
      name: (json['name'] ?? nested?['name'] ?? 'Alergen') as String,
      severityLevel: (json['severityLevel'] ?? json['severity'] ?? nested?['severityLevel'] ?? 'medium') as String,
      confidenceScore: ((json['confidenceScore'] ?? json['confidence'] ?? 0) as num).toDouble(),
    );
  }

  AllergenResultEntity toEntity() => AllergenResultEntity(
    allergenId: allergenId,
    name: name,
    severity: severityLevel,
    confidenceScore: confidenceScore,
  );
}
