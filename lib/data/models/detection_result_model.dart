import 'detection_model.dart';

class DetectionResultModel {
  final DetectionModel detection;
  final String message;

  DetectionResultModel({
    required this.detection,
    required this.message,
  });

  factory DetectionResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DetectionResultModel(
      detection: DetectionModel.fromJson(data['detection'] ?? data),
      message: data['message'] ?? 'Deteksi selesai',
    );
  }
}
