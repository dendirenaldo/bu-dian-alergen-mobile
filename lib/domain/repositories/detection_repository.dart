import 'dart:io';
import '../entities/detection_entity.dart';
import 'result.dart';

abstract class DetectionRepository {
  Future<Result<DetectionEntity>> detectAllergens(File image, {String? model});
  Future<Result<DetectionEntity>> detectFromText(String text, {String? model});
  Future<Result<DetectionEntity>> getDetection(int id);
  Future<Result<void>> deleteDetection(int id);
  Future<Map<String, dynamic>?> fetchPublicQuota();
}
