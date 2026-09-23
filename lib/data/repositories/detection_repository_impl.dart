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
  Future<Result<DetectionEntity>> detectAllergens(File image, {String? model}) async {
    try {
      final result = await _dataSource.detectAllergens(image, model: model);
      return Result.success(result.detection.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<DetectionEntity>> detectFromText(String text, {String? model}) async {
    try {
      final result = await _dataSource.detectFromText(text, model: model);
      return Result.success(result.detection.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchPublicQuota() => _dataSource.fetchPublicQuota();

  @override
  Future<Result<DetectionEntity>> getDetection(int id) async {
    try {
      final model = await _dataSource.getDetection(id);
      return Result.success(model.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<void>> deleteDetection(int id) async {
    try {
      await _dataSource.deleteDetection(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
