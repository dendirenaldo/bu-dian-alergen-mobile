import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/detection_models.dart';
import '../../core/network/api_result.dart';
import '../../core/utils/auth_token.dart';
import '../../core/utils/image_upload_helper.dart';
import '../models/detection_result_model.dart';

import '../models/detection_model.dart';

final _uuidRe = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

String _newUuid() {
  final r = Random.secure();
  String h(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${h(8)}-${h(4)}-4${h(3)}-${['8', '9', 'a', 'b'][r.nextInt(4)]}${h(3)}-${h(12)}';
}

/// Idempotency-Key baru (uuid v4) untuk setiap aksi deteksi.
String newIdempotencyKey() => _newUuid();

Future<String> ensureAnonId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('anon_id');
    if (v != null && _uuidRe.hasMatch(v)) return v;
    final nv = _newUuid();
    await prefs.setString('anon_id', nv);
    return nv;
  } catch (_) {
    return _newUuid();
  }
}

/// Maps backend `{statusCode, message, code, errors}` to a user-facing
/// [ApiError], preserving detection-specific hints (429 quota, 503 busy).
ApiError _detectionError(http.Response r, String fallback) {
  final parsed = parseApiError(r, fallback);
  if (r.statusCode == 429 && parsed.message.contains(fallback)) {
    return ApiError(
      statusCode: 429,
      message: 'Batas tercapai: deteksi hanya bisa 5x per jam. '
          'Coba lagi nanti atau masuk untuk lanjut. (HTTP 429)',
      code: parsed.code,
      fieldErrors: parsed.fieldErrors,
    );
  }
  if (r.statusCode == 503) {
    return ApiError(
      statusCode: 503,
      message:
          'Model sedang sibuk/belum tersedia, coba lagi nanti atau coba model lain. (HTTP 503)',
      code: parsed.code,
      fieldErrors: parsed.fieldErrors,
    );
  }
  return parsed;
}

String? _headerOf(Map<String, String> headers, String name) {
  final lower = name.toLowerCase();
  for (final e in headers.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }
  return null;
}

int? _retryAfterOf(Map<String, String> headers) {
  final v = _headerOf(headers, 'retry-after');
  if (v == null) return null;
  return int.tryParse(v.trim());
}

/// Satu event progres SSE dari `GET /api/v1/detections/stream`.
class SseProgressEvent {
  final String stage;
  final int progress;
  final String message;
  final int? etaMs;
  final Map<String, dynamic>? data;

  const SseProgressEvent({
    required this.stage,
    required this.progress,
    required this.message,
    this.etaMs,
    this.data,
  });

  factory SseProgressEvent.fromJson(Map<String, dynamic> json) {
    int progress = 0;
    final raw = json['progress'];
    if (raw is num) {
      progress = raw.toInt();
    } else {
      progress = int.tryParse(raw?.toString() ?? '') ?? 0;
    }
    progress = progress.clamp(0, 100);
    int? eta;
    final rawEta = json['etaMs'] ?? json['eta_ms'];
    if (rawEta is num) {
      eta = rawEta.toInt();
    } else if (rawEta != null) {
      eta = int.tryParse(rawEta.toString());
    }
    Map<String, dynamic>? data;
    final rawData = json['data'];
    if (rawData is Map) data = rawData.cast<String, dynamic>();
    return SseProgressEvent(
      stage: (json['stage'] ?? '').toString(),
      progress: progress,
      message: (json['message'] ?? '').toString(),
      etaMs: eta,
      data: data,
    );
  }

  bool get isDone => stage == 'done';
  bool get isError => stage == 'error';
}

/// Hasil POST deteksi beserta metadata header job.
class DetectionPostOutcome {
  final DetectionResultModel? result;
  final String? jobId;
  final String? modelFallback;
  final int? retryAfterSec;
  final bool isPending;

  const DetectionPostOutcome({
    this.result,
    this.jobId,
    this.modelFallback,
    this.retryAfterSec,
    this.isPending = false,
  });
}

/// Error POST yang membawa metadata header (jobId / retryAfter).
class DetectionPostException extends ApiException {
  final String? jobId;
  final int? retryAfterSec;
  const DetectionPostException(
    super.error, {
    this.jobId,
    this.retryAfterSec,
  });
}

class DetectionRemoteDataSource {
  final http.Client _client;

  DetectionRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool includeAnon = false, String? idempotencyKey}) async {
    String? token;
    try {
      token = await getValidToken();
    } catch (_) {
      token = null;
    }
    final map = <String, String>{
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (includeAnon || token == null) {
      map['x-anon-id'] = await ensureAnonId();
    }
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      map['Idempotency-Key'] = idempotencyKey.trim();
    }
    return map;
  }

  Future<void> _clearTokenBestEffort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {}
  }

  DetectionPostOutcome _outcomeOf(http.Response response) {
    final jobId = _headerOf(response.headers, 'x-job-id');
    final fallback = _headerOf(response.headers, 'x-model-fallback');
    final retryAfter = _retryAfterOf(response.headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionPostOutcome(
        result: DetectionResultModel.fromJson(jsonDecode(response.body)),
        jobId: jobId,
        modelFallback: fallback,
        retryAfterSec: retryAfter,
      );
    }
    if (response.statusCode == 202) {
      // 202 Accepted: job masih diproses, hasil menyusul via SSE.
      String? pendingJob = jobId;
      try {
        final body = jsonDecode(response.body);
        final data = body is Map ? (body['data'] as Map?) ?? body : null;
        pendingJob ??= (data?['uploadId'] ?? data?['jobId'])?.toString();
      } catch (_) {}
      return DetectionPostOutcome(
        jobId: pendingJob,
        modelFallback: fallback,
        retryAfterSec: retryAfter,
        isPending: true,
      );
    }
    throw DetectionPostException(
      _detectionError(response, 'Deteksi gagal'),
      jobId: jobId,
      retryAfterSec: retryAfter,
    );
  }

  DetectionPostOutcome _textOutcomeOf(http.Response response) {
    final jobId = _headerOf(response.headers, 'x-job-id');
    final fallback = _headerOf(response.headers, 'x-model-fallback');
    final retryAfter = _retryAfterOf(response.headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionPostOutcome(
        result: DetectionResultModel.fromJson(jsonDecode(response.body)),
        jobId: jobId,
        modelFallback: fallback,
        retryAfterSec: retryAfter,
      );
    }
    if (response.statusCode == 202) {
      String? pendingJob = jobId;
      try {
        final body = jsonDecode(response.body);
        final data = body is Map ? (body['data'] as Map?) ?? body : null;
        pendingJob ??= (data?['uploadId'] ?? data?['jobId'])?.toString();
      } catch (_) {}
      return DetectionPostOutcome(
        jobId: pendingJob,
        modelFallback: fallback,
        retryAfterSec: retryAfter,
        isPending: true,
      );
    }
    throw DetectionPostException(
      _detectionError(response, 'Deteksi teks gagal'),
      jobId: jobId,
      retryAfterSec: retryAfter,
    );
  }

  Future<DetectionResultModel> detectAllergens(File image, {String? model, String? idempotencyKey}) async {
    final outcome = await detectAllergensDetailed(image, model: model, idempotencyKey: idempotencyKey);
    final r = outcome.result;
    if (r != null) return r;
    throw const ApiException(ApiError(statusCode: 202, message: 'Deteksi masih diproses. Coba lagi.'));
  }

  Future<DetectionPostOutcome> detectAllergensDetailed(File image, {String? model, String? idempotencyKey}) async {
    ImageUploadHelper.validate(image);
    final m = DetectionModels.sanitize(model);

    Future<http.Response> send(String path, Map<String, String> headers) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.join(path)}?model=$m'),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: ImageUploadHelper.filenameOf(image.path),
        contentType: ImageUploadHelper.mediaTypeFor(image.path),
      ));
      final streamed = await _client.send(request).timeout(AppConfig.detectionTimeout);
      return http.Response.fromStream(streamed);
    }

    try {
      final headers = await _headers(idempotencyKey: idempotencyKey);
      final authed = headers.containsKey('Authorization');
      final response = await send(authed ? ApiEndpoints.detect : ApiEndpoints.detectPublic, headers);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return _outcomeOf(response);
      }
      if (response.statusCode == 401 && authed) {
        await _clearTokenBestEffort();
        final guestHeaders = await _headers(includeAnon: true, idempotencyKey: idempotencyKey);
        final retry = await send(ApiEndpoints.detectPublic, guestHeaders);
        if (retry.statusCode == 200 ||
            retry.statusCode == 201 ||
            retry.statusCode == 202) {
          return _outcomeOf(retry);
        }
        final jobId = _headerOf(retry.headers, 'x-job-id');
        throw DetectionPostException(
          _detectionError(retry, 'Deteksi gagal'),
          jobId: jobId,
          retryAfterSec: _retryAfterOf(retry.headers),
        );
      }
      throw DetectionPostException(
        _detectionError(response, 'Deteksi gagal'),
        jobId: _headerOf(response.headers, 'x-job-id'),
        retryAfterSec: _retryAfterOf(response.headers),
      );
    } on DetectionPostException {
      rethrow;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Deteksi gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Deteksi gagal'));
    }
  }

  Future<DetectionResultModel> detectFromText(String text, {String? model, String? idempotencyKey}) async {
    final outcome = await detectFromTextDetailed(text, model: model, idempotencyKey: idempotencyKey);
    final r = outcome.result;
    if (r != null) return r;
    throw const ApiException(ApiError(statusCode: 202, message: 'Deteksi masih diproses. Coba lagi.'));
  }

  Future<DetectionPostOutcome> detectFromTextDetailed(String text, {String? model, String? idempotencyKey}) async {
    final m = DetectionModels.sanitize(model);

    Future<http.Response> send(String path, Map<String, String> headers) async {
      final uri = Uri.parse('${AppConfig.join(path)}?model=$m');
      return _client
          .post(
            uri,
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(AppConfig.detectionTimeout);
    }

    try {
      final headers = await _headers(idempotencyKey: idempotencyKey);
      final authed = headers.containsKey('Authorization');
      final response =
          await send(authed ? ApiEndpoints.detectText : ApiEndpoints.detectPublicText, headers);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return _textOutcomeOf(response);
      }
      if (response.statusCode == 401 && authed) {
        await _clearTokenBestEffort();
        final guestHeaders = await _headers(includeAnon: true, idempotencyKey: idempotencyKey);
        final retry = await send(ApiEndpoints.detectPublicText, guestHeaders);
        if (retry.statusCode == 200 ||
            retry.statusCode == 201 ||
            retry.statusCode == 202) {
          return _textOutcomeOf(retry);
        }
        throw DetectionPostException(
          _detectionError(retry, 'Deteksi teks gagal'),
          jobId: _headerOf(retry.headers, 'x-job-id'),
          retryAfterSec: _retryAfterOf(retry.headers),
        );
      }
      throw DetectionPostException(
        _detectionError(response, 'Deteksi teks gagal'),
        jobId: _headerOf(response.headers, 'x-job-id'),
        retryAfterSec: _retryAfterOf(response.headers),
      );
    } on DetectionPostException {
      rethrow;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Deteksi teks gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Deteksi teks gagal'));
    }
  }

  /// Streaming SSE manual via [http.Client] (tanpa package SSE berat).
  ///
  /// Membuka `GET /api/v1/detections/stream?uploadId=...` dengan header
  /// `Accept: text/event-stream`, mem-parsing baris `data: {...}` menjadi
  /// [SseProgressEvent]. Komentar SSE (`:ping`) dan baris kosong diabaikan.
  Stream<SseProgressEvent> watchJob(String uploadId) {
    final controller = StreamController<SseProgressEvent>();
    final streamClient = http.Client();
    bool closed = false;

    Future<void> run() async {
      try {
        final headers = await _headers();
        final req = http.Request(
          'GET',
          Uri.parse('${AppConfig.join(ApiEndpoints.stream)}?uploadId=${Uri.encodeQueryComponent(uploadId)}'),
        );
        req.headers.addAll({...headers, 'Accept': 'text/event-stream'});
        final streamed = await streamClient.send(req).timeout(const Duration(seconds: 30));
        if (streamed.statusCode != 200) {
          throw ApiException(ApiError(
            statusCode: streamed.statusCode,
            message: 'Gagal membuka progres (HTTP ${streamed.statusCode})',
          ));
        }
        final buffer = StringBuffer();
        await for (final chunk in streamed.stream.transform(utf8.decoder)) {
          if (closed || controller.isClosed) break;
          buffer.write(chunk);
          var text = buffer.toString();
          var idx = text.indexOf('\n');
          while (idx != -1) {
            final line = text.substring(0, idx).trim();
            text = text.substring(idx + 1);
            if (line.startsWith('data:')) {
              final payload = line.substring(5).trim();
              if (payload.isNotEmpty) {
                try {
                  final json = jsonDecode(payload);
                  if (json is Map) {
                    controller.add(SseProgressEvent.fromJson(json.cast<String, dynamic>()));
                  }
                } catch (_) {
                  // Abaikan baris data yang bukan JSON valid.
                }
              }
            }
            // Abaikan komentar heartbeat (`:ping`) & baris kosong.
            idx = text.indexOf('\n');
          }
          buffer.clear();
          buffer.write(text);
        }
        // Sisa buffer tanpa newline trailing.
        final rest = buffer.toString().trim();
        if (rest.startsWith('data:') && !controller.isClosed) {
          try {
            final json = jsonDecode(rest.substring(5).trim());
            if (json is Map) {
              controller.add(SseProgressEvent.fromJson(json.cast<String, dynamic>()));
            }
          } catch (_) {}
        }
        if (!controller.isClosed) await controller.close();
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      } finally {
        streamClient.close();
      }
    }

    controller.onCancel = () {
      closed = true;
      try {
        streamClient.close();
      } catch (_) {}
    };

    unawaited(run());
    return controller.stream;
  }

  /// `DELETE /api/v1/detections/job/:id` — batalkan job + refund kuota.
  Future<void> cancelJob(String jobId) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.jobCancel(jobId)));
      final response = await _client.delete(uri, headers: await _headers()).timeout(AppConfig.timeout);
      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        return;
      }
      throw ApiException(_detectionError(response, 'Gagal membatalkan job'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal membatalkan job'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal membatalkan job'));
    }
  }

  Future<Map<String, dynamic>?> fetchPublicQuota() async {
    try {
      String? token;
      try {
        token = await getValidToken();
      } catch (_) {
        token = null;
      }
      if (token != null) return null;
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.detectPublicQuota));
      final response = await _client
          .get(uri, headers: await _headers(includeAnon: true))
          .timeout(AppConfig.timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body['data'] is Map) ? body['data'] : body;
        return (data as Map).cast<String, dynamic>();
      }
      throw ApiException(_detectionError(response, 'Gagal memuat kuota'));
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat kuota'));
    }
  }

  Future<DetectionModel> getDetection(int id) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.historyDetail(id)));
      final response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.timeout);
      if (response.statusCode == 200) {
        return DetectionModel.fromJson(jsonDecode(response.body));
      }
      throw ApiException(_detectionError(response, 'Gagal memuat detail'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memuat detail'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat detail'));
    }
  }

  Future<void> deleteDetection(int id) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.historyDetail(id)));
      final response = await _client.delete(uri, headers: await _headers()).timeout(AppConfig.timeout);
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw ApiException(_detectionError(response, 'Gagal menghapus deteksi'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal menghapus deteksi'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal menghapus deteksi'));
    }
  }
}

void unawaited(Future<void> future) {}
