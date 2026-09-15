import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../core/utils/image_upload_helper.dart';
import 'storage_service.dart';

/// Service legacy (tidak dipakai alur utama provider, tapi diperbaiki
/// agar tidak menembak URL salah jika dipakai di masa depan).
class ApiService {
  final StorageService _storageService;
  final http.Client _client;

  ApiService(this._storageService) : _client = http.Client();

  String get baseUrl => AppConfig.normalizedBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse(AppConfig.join(endpoint));
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    return _client.get(_uri(endpoint, queryParams), headers: headers).timeout(AppConfig.timeout);
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    return _client.post(
      _uri(endpoint),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(AppConfig.timeout);
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    return _client.put(
      _uri(endpoint),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(AppConfig.timeout);
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _client.delete(_uri(endpoint), headers: headers).timeout(AppConfig.timeout);
  }

  Future<http.Response> uploadMultipart(String endpoint, String filePath, {Map<String, String>? fields}) async {
    final token = await _storageService.getToken();
    var request = http.MultipartRequest('POST', _uri(endpoint));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    // Content-type eksplisit (lihat ImageUploadHelper): default fromPath
    // application/octet-stream selalu ditolak backend.
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      filePath,
      filename: ImageUploadHelper.filenameOf(filePath),
      contentType: ImageUploadHelper.mediaTypeFor(filePath),
    ));
    fields?.forEach((key, value) => request.fields[key] = value);
    final streamedResponse = await _client.send(request).timeout(AppConfig.detectionTimeout);
    return http.Response.fromStream(streamedResponse);
  }
}
