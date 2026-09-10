import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService;
  final http.Client _client;

  ApiService(this._storageService) : _client = http.Client();

  String get baseUrl => AppConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    return _client.get(uri, headers: headers);
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    return _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    return _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> uploadMultipart(String endpoint, String filePath, {Map<String, String>? fields}) async {
    final token = await _storageService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    fields?.forEach((key, value) => request.fields[key] = value);
    final streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }
}
