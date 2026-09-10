import 'dart:io';
import '../../domain/entities/detection_entity.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../domain/repositories/result.dart';
import '../datasources/detection_remote_datasource.dart';

class DetectionRepositoryImpl implements DetectionRepository {
  final DetectionRemoteDataSource _dataSource;

  DetectionRepositoryImpl({DetectionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? DetectionRemoteDataSource();

  @override
  Future<Result<DetectionEntity>> detectAllergens(File image) async {
    try {
      final result = await _dataSource.detectAllergens(image);
      return Result.success(result.detection.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<DetectionEntity>> getDetection(int id) async {
    try {
      // Placeholder for get single detection
      return Result.failure('Not implemented');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
