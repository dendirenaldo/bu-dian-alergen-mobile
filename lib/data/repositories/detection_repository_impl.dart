import 'dart:io';
import '../../core/network/api_result.dart';
import '../../domain/entities/detection_entity.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../domain/repositories/result.dart';
import '../datasources/detection_remote_datasource.dart';

/// Hasil POST yang diperkaya metadata job (untuk progres SSE + retry).
class DetailedDetectionResult {
  final Result<DetectionEntity> result;
  final String? jobId;
  final String? modelFallback;
  final int? retryAfterSec;
  final bool isPending;

  const DetailedDetectionResult({
    required this.result,
    this.jobId,
    this.modelFallback,
    this.retryAfterSec,
    this.isPending = false,
  });
}

class DetectionRepositoryImpl implements DetectionRepository {
  final DetectionRemoteDataSource _dataSource;

  DetectionRepositoryImpl({DetectionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? DetectionRemoteDataSource();

  @override
  Future<Result<DetectionEntity>> detectAllergens(File image, {String? model}) async {
    final detailed = await detectAllergensDetailed(image, model: model);
    return detailed.result;
  }

  Future<DetailedDetectionResult> detectAllergensDetailed(
    File image, {
    String? model,
    String? idempotencyKey,
  }) async {
    try {
      final outcome = await _dataSource.detectAllergensDetailed(
        image,
        model: model,
        idempotencyKey: idempotencyKey,
      );
      if (outcome.result != null) {
        return DetailedDetectionResult(
          result: Result.success(outcome.result!.detection.toEntity()),
          jobId: outcome.jobId,
          modelFallback: outcome.modelFallback,
          retryAfterSec: outcome.retryAfterSec,
        );
      }
      // 202 pending: teruskan jobId agar caller membuka SSE.
      return DetailedDetectionResult(
        result: Result.failure(
          'Deteksi masih diproses. Menunggu progres…',
          statusCode: 202,
        ),
        jobId: outcome.jobId,
        modelFallback: outcome.modelFallback,
        retryAfterSec: outcome.retryAfterSec,
        isPending: true,
      );
    } on DetectionPostException catch (e) {
      return DetailedDetectionResult(
        result: Result.failureFromApi(e.error),
        jobId: e.jobId,
        retryAfterSec: e.retryAfterSec,
      );
    } on ApiException catch (e) {
      return DetailedDetectionResult(result: Result.failureFromApi(e.error));
    } catch (e) {
      return DetailedDetectionResult(
        result: Result.failure(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  @override
  Future<Result<DetectionEntity>> detectFromText(String text, {String? model}) async {
    final detailed = await detectFromTextDetailed(text, model: model);
    return detailed.result;
  }

  Future<DetailedDetectionResult> detectFromTextDetailed(
    String text, {
    String? model,
    String? idempotencyKey,
  }) async {
    try {
      final outcome = await _dataSource.detectFromTextDetailed(
        text,
        model: model,
        idempotencyKey: idempotencyKey,
      );
      if (outcome.result != null) {
        return DetailedDetectionResult(
          result: Result.success(outcome.result!.detection.toEntity()),
          jobId: outcome.jobId,
          modelFallback: outcome.modelFallback,
          retryAfterSec: outcome.retryAfterSec,
        );
      }
      return DetailedDetectionResult(
        result: Result.failure(
          'Deteksi masih diproses. Menunggu progres…',
          statusCode: 202,
        ),
        jobId: outcome.jobId,
        modelFallback: outcome.modelFallback,
        retryAfterSec: outcome.retryAfterSec,
        isPending: true,
      );
    } on DetectionPostException catch (e) {
      return DetailedDetectionResult(
        result: Result.failureFromApi(e.error),
        jobId: e.jobId,
        retryAfterSec: e.retryAfterSec,
      );
    } on ApiException catch (e) {
      return DetailedDetectionResult(result: Result.failureFromApi(e.error));
    } catch (e) {
      return DetailedDetectionResult(
        result: Result.failure(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  /// Streaming progres SSE untuk [uploadId].
  Stream<SseProgressEvent> watchJob(String uploadId) =>
      _dataSource.watchJob(uploadId);

  /// Batalkan job SSE + refund kuota (best-effort dari provider).
  Future<Result<void>> cancelJob(String jobId) async {
    try {
      await _dataSource.cancelJob(jobId);
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
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
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<void>> deleteDetection(int id) async {
    try {
      await _dataSource.deleteDetection(id);
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
