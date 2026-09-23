import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/detection_models.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getString('anon_id');
  if (v != null && _uuidRe.hasMatch(v)) return v;
  final nv = _newUuid();
  await prefs.setString('anon_id', nv);
  return nv;
}

String _errMsg(http.Response r, String fallback) {
  String serverMsg = '';
  try {
    final body = jsonDecode(r.body);
    if (body is Map && body['message'] != null) {
      serverMsg = body['message'].toString();
    }
  } catch (_) {
    final snippet = r.body.length > 120 ? '${r.body.substring(0, 120)}…' : r.body;
    return '$fallback (HTTP ${r.statusCode} @ ${r.request?.url} :: $snippet)';
  }
  // Pesan ramah per status (tetap sertakan pesan server bila ada).
  if (r.statusCode == 429) {
    return serverMsg.isNotEmpty
        ? '$serverMsg (HTTP 429)'
        : 'Batas tercapai: deteksi hanya bisa 5x per jam. Coba lagi nanti atau masuk untuk lanjut. (HTTP 429)';
  }
  if (r.statusCode == 503) {
    return 'Model sedang sibuk/belum tersedia, coba lagi nanti atau coba model lain. (HTTP 503)';
  }
  if (r.statusCode == 401) {
    return 'Sesi berakhir. Silakan masuk ulang atau coba tanpa masuk. (HTTP 401)';
  }
  if (serverMsg.isNotEmpty) return '$serverMsg (HTTP ${r.statusCode})';
  return '$fallback (HTTP ${r.statusCode})';
}

class DetectionRemoteDataSource {
  final http.Client _client;

  DetectionRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool includeAnon = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final map = <String, String>{
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (includeAnon || token == null) {
      map['x-anon-id'] = await ensureAnonId();
    }
    return map;
  }

  Future<DetectionResultModel> detectAllergens(File image, {String? model}) async {
    // Validasi lokal dulu: hemat kuota & pesan error langsung jelas.
    ImageUploadHelper.validate(image);
    final m = DetectionModels.sanitize(model);

    Future<http.Response> send(String path, Map<String, String> headers) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.join(path)}?model=$m'),
      );
      request.headers.addAll(headers);
      // WAJIB contentType eksplisit: fromPath default application/octet-stream
      // yang selalu ditolak backend (400 "File harus berupa gambar").
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: ImageUploadHelper.filenameOf(image.path),
        contentType: ImageUploadHelper.mediaTypeFor(image.path),
      ));
      final streamed = await _client.send(request).timeout(AppConfig.detectionTimeout);
      return http.Response.fromStream(streamed);
    }

    final headers = await _headers();
    final authed = headers.containsKey('Authorization');
    final response = await send(authed ? ApiEndpoints.detect : ApiEndpoints.detectPublic, headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionResultModel.fromJson(jsonDecode(response.body));
    }
    // Token basi/kadaluarsa: sekali retry ke endpoint publik sebagai tamu.
    if (response.statusCode == 401 && authed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      final guestHeaders = await _headers(includeAnon: true);
      final retry = await send(ApiEndpoints.detectPublic, guestHeaders);
      if (retry.statusCode == 200 || retry.statusCode == 201) {
        return DetectionResultModel.fromJson(jsonDecode(retry.body));
      }
      throw Exception(_errMsg(retry, 'Deteksi gagal'));
    }
    throw Exception(_errMsg(response, 'Deteksi gagal'));
  }

  /// Klasifikasi dari teks komposisi.
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

    final headers = await _headers();
    final authed = headers.containsKey('Authorization');
    final response =
        await send(authed ? ApiEndpoints.detectText : ApiEndpoints.detectPublicText, headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionResultModel.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401 && authed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      final guestHeaders = await _headers(includeAnon: true);
      final retry = await send(ApiEndpoints.detectPublicText, guestHeaders);
      if (retry.statusCode == 200 || retry.statusCode == 201) {
        return DetectionResultModel.fromJson(jsonDecode(retry.body));
      }
      throw Exception(_errMsg(retry, 'Deteksi teks gagal'));
    }
    throw Exception(_errMsg(response, 'Deteksi teks gagal'));
  }

  /// Sisa kuota tanpa login (5x per jam). Return null bila login (unlimited).
  Future<Map<String, dynamic>?> fetchPublicQuota() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('auth_token') != null) return null;
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.detectPublicQuota));
    final response = await _client
        .get(uri, headers: await _headers(includeAnon: true))
        .timeout(AppConfig.timeout);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      return (data as Map).cast<String, dynamic>();
    }
    return null;
  }

  Future<DetectionModel> getDetection(int id) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.historyDetail(id)));
    final response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.timeout);
    if (response.statusCode == 200) {
      return DetectionModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Gagal memuat detail'));
  }

  Future<void> deleteDetection(int id) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.historyDetail(id)));
    final response = await _client.delete(uri, headers: await _headers()).timeout(AppConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_errMsg(response, 'Gagal menghapus deteksi'));
  }
}
