import '../../domain/entities/detection_entity.dart';

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double _asDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

class DetectionModel {
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
  final List<AllergenResultModel>? detectionAllergens;

  DetectionModel({
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
    this.detectionAllergens,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final rawCreated = data['createdAt'] as String?;
    final rawList = data['detectionAllergens'] ??
        data['allergens'] ??
        (data['rawModelOutput'] is Map ? (data['rawModelOutput'] as Map)['allergens'] : null);
    final rawUid = data['userId'];
    int? userId;
    if (rawUid == null) {
      userId = null;
    } else if (rawUid is int) {
      userId = rawUid;
    } else if (rawUid is num) {
      userId = rawUid.toInt();
    } else {
      userId = int.tryParse(rawUid.toString());
    }
    return DetectionModel(
      id: _asInt(data['id']),
      userId: userId,
      imageUrl: data['imageUrl'] as String?,
      ocrText: (data['ocrText'] ?? data['ocr_text']) as String?,
      result: (data['result'] ?? 'unknown') as String,
      confidenceScore: _asDouble(data['confidenceScore'] ?? data['confidence_score']),
      processingTimeMs: data['processingTimeMs'] != null || data['processing_time_ms'] != null
          ? _asInt(data['processingTimeMs'] ?? data['processing_time_ms'])
          : null,
      detectionMethod: (data['detectionMethod'] ?? data['detection_method'] ?? 'image_ocr') as String,
      modelName: (data['modelName'] ?? data['model_name'] ?? (data['rawModelOutput'] as Map?)?['model_name']) as String?,
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) ?? DateTime.now() : DateTime.now(),
      detectionAllergens: rawList is List
          ? rawList.map((e) => AllergenResultModel.fromJson((e as Map).cast<String, dynamic>())).toList()
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
    modelName: modelName,
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
      allergenId: _asInt(json['allergenId'] ?? nested?['id']),
      name: (json['name'] ?? nested?['name'] ?? 'Alergen') as String,
      severityLevel: (json['severityLevel'] ?? json['severity'] ?? nested?['severityLevel'] ?? 'medium') as String,
      confidenceScore: _asDouble(json['confidenceScore'] ?? json['confidence']),
    );
  }

  AllergenResultEntity toEntity() => AllergenResultEntity(
    allergenId: allergenId,
    name: name,
    severity: severityLevel,
    confidenceScore: confidenceScore,
  );
}
