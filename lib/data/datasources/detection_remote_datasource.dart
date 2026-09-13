import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/detection_result_model.dart';

import '../models/detection_model.dart';

class DetectionRemoteDataSource {
  final http.Client _client;

  DetectionRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<DetectionResultModel> detectAllergens(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.detect}'),
    );

    request.headers.addAll(await _headers());
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await _client.send(request).timeout(AppConfig.timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DetectionResultModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Detection failed');
  }

  Future<DetectionModel> getDetection(int id) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.history}/$id');
    final response = await _client.get(uri, headers: await _headers()).timeout(AppConfig.timeout);
    if (response.statusCode == 200) {
      return DetectionModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal memuat detail');
  }
}
