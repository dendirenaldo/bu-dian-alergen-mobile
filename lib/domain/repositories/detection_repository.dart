import 'dart:io';
import '../entities/detection_entity.dart';
import 'result.dart';

abstract class DetectionRepository {
  Future<Result<DetectionEntity>> detectAllergens(File image);
  Future<Result<DetectionEntity>> detectFromText(String text);
  Future<Result<DetectionEntity>> getDetection(int id);
  Future<Result<void>> deleteDetection(int id);
}
