import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/image_upload_helper.dart';
import '../models/detection_result_model.dart';

import '../models/detection_model.dart';

String _errMsg(http.Response r, String fallback) {
  try {
    final body = jsonDecode(r.body);
    if (body is Map && body['message'] != null) {
      return '${body['message']} (HTTP ${r.statusCode})';
    }
  } catch (_) {
    final snippet = r.body.length > 120 ? '${r.body.substring(0, 120)}…' : r.body;
    return '$fallback (HTTP ${r.statusCode} @ ${r.request?.url} :: $snippet)';
  }
  return '$fallback (HTTP ${r.statusCode})';
}

class DetectionRemoteDataSource {
  final http.Client _client;

  DetectionRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<DetectionResultModel> detectAllergens(File image) async {
    // Validasi lokal dulu: hemat kuota & pesan error langsung jelas.
    ImageUploadHelper.validate(image);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.join(ApiEndpoints.detect)),
    );

    request.headers.addAll(await _headers());
    // WAJIB contentType eksplisit: fromPath default application/octet-stream
    // yang selalu ditolak backend (400 "File harus berupa gambar").
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
      filename: ImageUploadHelper.filenameOf(image.path),
      contentType: ImageUploadHelper.mediaTypeFor(image.path),
    ));

    final streamedResponse = await _client.send(request).timeout(AppConfig.detectionTimeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionResultModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Deteksi gagal'));
  }

  /// Klasifikasi dari teks komposisi. Backend: POST /api/v1/detections/text {text}.
  Future<DetectionResultModel> detectFromText(String text) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.detectText));
    final response = await _client
        .post(
          uri,
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(AppConfig.detectionTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionResultModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Deteksi teks gagal'));
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
