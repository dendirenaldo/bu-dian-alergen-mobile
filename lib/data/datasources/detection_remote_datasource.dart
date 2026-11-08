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

class DetectionRemoteDataSource {
  final http.Client _client;

  DetectionRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool includeAnon = false}) async {
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
    return map;
  }

  Future<void> _clearTokenBestEffort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {}
  }

  Future<DetectionResultModel> detectAllergens(File image, {String? model}) async {
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
      final headers = await _headers();
      final authed = headers.containsKey('Authorization');
      final response = await send(authed ? ApiEndpoints.detect : ApiEndpoints.detectPublic, headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DetectionResultModel.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 401 && authed) {
        await _clearTokenBestEffort();
        final guestHeaders = await _headers(includeAnon: true);
        final retry = await send(ApiEndpoints.detectPublic, guestHeaders);
        if (retry.statusCode == 200 || retry.statusCode == 201) {
          return DetectionResultModel.fromJson(jsonDecode(retry.body));
        }
        throw ApiException(_detectionError(retry, 'Deteksi gagal'));
      }
      throw ApiException(_detectionError(response, 'Deteksi gagal'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Deteksi gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Deteksi gagal'));
    }
  }

  Future<DetectionResultModel> detectFromText(String text, {String? model}) async {
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
      final headers = await _headers();
      final authed = headers.containsKey('Authorization');
      final response =
          await send(authed ? ApiEndpoints.detectText : ApiEndpoints.detectPublicText, headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DetectionResultModel.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 401 && authed) {
        await _clearTokenBestEffort();
        final guestHeaders = await _headers(includeAnon: true);
        final retry = await send(ApiEndpoints.detectPublicText, guestHeaders);
        if (retry.statusCode == 200 || retry.statusCode == 201) {
          return DetectionResultModel.fromJson(jsonDecode(retry.body));
        }
        throw ApiException(_detectionError(retry, 'Deteksi teks gagal'));
      }
      throw ApiException(_detectionError(response, 'Deteksi teks gagal'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Deteksi teks gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Deteksi teks gagal'));
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
